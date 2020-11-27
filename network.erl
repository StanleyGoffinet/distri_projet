-module(network).
-export([create_list_node/1, node_initialisation/5, getId/1, node_create/6, node/6]).
-import(linkedlist,[receiver/7, sender/6, select_peer_random/1]).

add(ID,[])->[#{id => ID, list_neighbors => []}];
add(ID,[ #{id := IDprev, list_neighbors := List_neigh_prev} |T ])->
  [#{id =>ID, list_neighbors => [#{id_neighbors=>IDprev, age_neighbors=>0}]},
   #{id => IDprev, list_neighbors => lists:append([#{id_neighbors=>ID,age_neighbors=>0}],List_neigh_prev)} |T].

create_list_node(NbrNode)->create_list_node(NbrNode,[]).
create_list_node(0,Acc)->lists:reverse(Acc);
create_list_node(NbrNode,List)-> create_list_node(NbrNode-1, add(NbrNode, List)).

% A is a list of node (output of create_list_node)
node_initialisation(A, H, S, C, Pull)->node_initialisation(A, [], H, S, C, Pull).
node_initialisation([], Acc, H, S, C, Pull)-> Acc;
node_initialisation([#{id := ID_receiver_itself, list_neighbors := View} |T], Acc, H, S, C, Pull)->
  node_initialisation(T, lists:append([spawn(linkedlist, node_create, [ID_receiver_itself, View, H, S, C, Pull])], Acc), H, S, C, Pull).

getId(Nbr)->list_to_atom(integer_to_list(Nbr)).

node_create(IDreceiver, View, H, S, C, Pull)->
  register(getId(IDreceiver), spawn(linkedlist, receiver, [View,self(), IDreceiver, H, S, C, Pull])),
  IDsender = spawn(linkedlist, sender, [self(),IDreceiver, H, S, C, Pull]),
  node(View, IDsender,IDreceiver, H, S, C).

node(View, IDsender,IDreceiver, H, S, C)->
  if IDreceiver =:= 1 ->
    io:format("View node : ~p~n", [View]);
  true -> 0
  end,

  receive
    #{message := "time"}->
    IDsender ! View ,  %message recu du main thread => le sender doit envoyer un message a un noeud voisin
    node(View,IDsender,IDreceiver, H, S, C);
    #{message := "get_neighbors"} ->
      node(View,IDsender,IDreceiver, H, S, C);
    #{message := "view_receiver" , view := New_View}->
      if IDreceiver =:= 1 ->
        % io:format("neighbors updated : ~p~n", [New_View]),
        node(New_View, IDsender,IDreceiver, H, S, C); %message recu de la prt du receiver => mise a jour de la view
      true ->
         node(New_View, IDsender,IDreceiver, H, S, C) %message recu de la prt du receiver => mise a jour de la view
      end;
    #{message := "view_sender" , view := New_View}->
      node(New_View, IDsender,IDreceiver, H, S, C); %message recu de la prt du sender => mise a jour de la view
    #{message := "dead"} ->
      IDsender ! "dead",
      getId(IDreceiver)! "dead";
    #{message := "ask_id_receiver", addresse_retour := Addr} ->
      Addr ! #{message => "response_id_receiver", id_receiver => IDreceiver},
      node(View, IDsender,IDreceiver, H, S, C)
  end.
