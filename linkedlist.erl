-module(linkedlist).
-export([receiver/7, sender/6, select_peer_random/1]).
-import(viewselect, [view_select/5]).
-import(network,[create_list_node/1, node_initialisation/5, getId/1, node_create/6, node/6]).

%getNeighbors(IDNode,[])-> "error, IDNode is not in the given list";
%getNeighbors(IDNode, [#{id := IDNode,list_neighbors:= List_neigh}|T])-> List_neigh;
%getNeighbors(IDNode, [H|T])->getNeighbors(IDNode, T).

%------------------------- PASSIF ---------------------------------

receiver(View, IDParent, Id_receiver, H, S, C, Pull)->
  receive
    "dead" ->
      io:format(" receiver dead ~p~n", [getId(Id_receiver)]);

    #{id_sender_brut := IDsender, view := View_receive}-> %le receiver recoit une view d'un autre noeud. Pour le moment, il l'append a sa list de view
      % if pull
      if Pull =:= 'true'->
        Buffer = [#{id_neighbors=>Id_receiver, age_neighbors=>0}],
        View_permute = highest_age_to_end(View, H),
        {First, Second} = lists:split(min(length(View_permute), floor(C/2)-1), View_permute),
        Buffer_append = lists:append(Buffer, First),
        IDsender ! #{view_pull =>  Buffer_append},
        View_select = view_select(H, S, C, View_receive, View),
        New_view = increaseAge(View_select),
        IDParent ! #{message => "view_receiver", view => New_view};
      true ->
        View_select = view_select(H, S, C, View_receive, View),
        New_view = increaseAge(View_select),
        IDParent ! #{message => "view_receiver", view => New_view}
      end,
    receiver(New_view, IDParent, Id_receiver, H, S, C, Pull)
  end.

select_peer_random(View) -> lists:nth(rand:uniform(length(View)), View).

%---------------------------- ACTIF --------------------------------------------------

sender(IDParent,IDReceiver_itself, H, S, C, Pull)->
  receive
    "dead" ->
      io:format(" sender dead ~p~n", [getId(IDReceiver_itself)]);

    View-> % le sender va devoir envoyer un message a un autre node. Pour le moment, il l'envoie au premier noeud de la list
      #{id_neighbors := Id_Peer, age_neighbors := Age} = select_peer_random(View),
      % if push
      Buffer = [#{id_neighbors=>IDReceiver_itself, age_neighbors=>0}],
      View_permute = highest_age_to_end(View, H),
      {First, Second} = lists:split(min(length(View_permute), floor(C/2)-1), View_permute),
      Buffer_append = lists:append(Buffer, First),
      ToTest = getId(Id_Peer),
      case whereis(ToTest) =/= undefined of true ->
        getId(Id_Peer) ! #{id_sender_brut => self(), view =>  Buffer_append},

      % if pull
        if Pull =:='true' ->
          receive
            #{view_pull := View_receive} ->
              New_View = view_select(H, S, C, View_receive, View_permute),
              View_increase_Age_Pull = increaseAge(New_View),
              IDParent ! #{message => "view_sender", view => View_increase_Age_Pull}

              after 1500 ->
                View_increase_Age = increaseAge(View_permute),
                IDParent ! #{message => "view_sender", view => View_increase_Age}

              end; %receive
            true-> % if Pull =:='true'
              View_increase_Age = increaseAge(View_permute),
              IDParent ! #{message => "view_sender", view => View_increase_Age}
            end, % if Pull =:='true'
            sender(IDParent,IDReceiver_itself, H, S, C, Pull);
       false-> %   case whereis(ToTest) =/= undefined of true ->
         sender(IDParent,IDReceiver_itself, H, S, C, Pull)
      end %   if whereis(getId(Id_Peer)) =/= undefined
  end.

% La fonction place les H plus vieux éléments à la fin de la liste View
highest_age_to_end(View, H) -> highest_age_to_end(View, H, []).
highest_age_to_end(View, 0, Acc) -> lists:append(View, Acc);
highest_age_to_end(View, H, Acc) -> highest_age_to_end(lists:delete(getHighestAge(View), View), H-1, getHighestAge(View)).

%input : a view
% output : getHighestAge renvoie le neighbor avec le plus grand age.
%Si deux neighbor ont le meme age, getHighestAge renvoie le premier neighbor qui apparait dans la liste
getHighestAge(View)-> getHighestAge(View, #{id_neighbors=> -1, age_neighbors => -1}).
getHighestAge([], Acc)-> Acc;
getHighestAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := IDMax, age_neighbors := NbrMax}) ->
  if Nbr>NbrMax -> getHighestAge(T, #{id_neighbors => ID, age_neighbors => Nbr});
  true -> getHighestAge(T, #{id_neighbors => IDMax, age_neighbors => NbrMax})
end.

increaseAge(View)->increaseAge(View, []).
increaseAge([], Acc)-> lists:reverse(Acc);
increaseAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc) -> increaseAge(T, lists:append([#{id_neighbors => ID, age_neighbors => Nbr+1}], Acc)).


%min_age([], #{id_neighbors := ID_min, age_neighbors := Nbr_min})-> #{id_neighbors => ID_min, age_neighbors => Nbr_min};
%min_age([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := ID_min, age_neighbors := Nbr_min})->
%if ID =:= ID_min , Nbr<Nbr_min -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr});
%true -> min_age(T, #{id_neighbors => ID_min, age_neighbors => Nbr_min})
%end.
