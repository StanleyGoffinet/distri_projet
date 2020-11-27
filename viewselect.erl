-module(viewselect).
-export([view_select/5]).
-import(linkedlist, [select_peer_random/1]).

view_select(H, S, C, View_receive, View) ->
  View_append = lists:append(View, View_receive),
  % 1.0
  View_without_duplicate = remove_duplicate(View_append),
  % 2.0
  View_remove_old = remove_highest_age(View_without_duplicate, nbr_to_remove(H, length(View_without_duplicate)-C)),
  % 3.0
  View_remove_first = remove_first_element(View_remove_old, nbr_to_remove(S, length(View_remove_old)-C)),
  % 4.0
  remove_random(View_remove_first, max(0, length(View_remove_first)-C)).

remove_duplicate(View) -> remove_duplicate(View, View).
remove_duplicate([], Acc) -> Acc;
remove_duplicate([H|T], Acc) -> remove_duplicate(T, remove_older(H, Acc)).

% 1.1
remove_older(Tuple_ref, View)-> remove_older(Tuple_ref, View, [], 'false').
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [], Acc, Flag )-> lists:reverse(Acc);
remove_older(#{id_neighbors := ID_ref, age_neighbors := Nbr_ref}, [#{id_neighbors := ID, age_neighbors := Nbr}|T], Acc, Flag)->
  if ID_ref =:= ID , Nbr>Nbr_ref -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, Flag);
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'false' -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], 'true');
  ID_ref =:= ID, Nbr =:= Nbr_ref , Flag =:= 'true' -> remove_older (#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, Acc, 'true');
  true -> remove_older(#{id_neighbors => ID_ref, age_neighbors => Nbr_ref}, T, [#{id_neighbors => ID, age_neighbors => Nbr}|Acc], Flag)
end.

% 2.0 La fonction retire les H plus view élements de la liste View
remove_highest_age(View, 0) -> View;
remove_highest_age(View, H) ->
  remove_highest_age(lists:delete(getHighestAge(View),View),H-1).

% 2.1
%input : a view
% output : getHighestAge renvoie le neighbor avec le plus grand age.
%Si deux neighbor ont le meme age, getHighestAge renvoie le premier neighbor qui apparait dans la liste
getHighestAge(View)-> getHighestAge(View, #{id_neighbors=> -1, age_neighbors => -1}).
getHighestAge([], Acc)-> Acc;
getHighestAge([#{id_neighbors := ID, age_neighbors := Nbr}|T], #{id_neighbors := IDMax, age_neighbors := NbrMax}) ->
  if Nbr>NbrMax -> getHighestAge(T, #{id_neighbors => ID, age_neighbors => Nbr});
  true -> getHighestAge(T, #{id_neighbors => IDMax, age_neighbors => NbrMax})
end.

% 3.0 La fonction retire les S premiers éléments de la liste
remove_first_element(View, 0) -> View;
remove_first_element([H|T], S) -> remove_first_element(T, S-1).

% 4.0 N est le nombre d element a enlever
remove_random (View, 0) ->
  View;
remove_random (View, N) ->
  remove_random(lists:delete(select_peer_random(View), View), N-1).

% 2.1 and 3.1
nbr_to_remove(X, Y)->
  if X=<0 -> 0;
  Y=<0->0;
  true-> min(X,Y)
end.
