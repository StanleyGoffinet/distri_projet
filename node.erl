- module(node).
- export([init/8,passive/6,active/7, permute/1,moveOldest/2,remove_Oldest/2,increaseAge/1,listen/0,remove_Dup/1]).
- import(network,[getNeighbors/2]).
- record(state, {id, pid, buffer, view}).


listen() ->
  receive
    {init,Id,C,H,S,PushPull,T,PeerS,ListPid} ->
      init(Id,C,H,S,PushPull,T,PeerS,ListPid)
    end.


init(Id, C, H, S, PushPull,T, PeerS, List) ->
  State = #state{id = Id, pid = self(), buffer = [], view = getNeigh(List,Id)},
  ActivePid = spawn(node, active, [State,H,S,C,PushPull,T,PeerS]),
  PassivePid = spawn(node, passive, [State,H,S,C,PushPull,PeerS]),
  node_hub(ActivePid,PassivePid,true).


node_hub(ActivePid,PassivePid,Alive) ->
  if
    Alive ->
      receive
        {getView,From} ->
          ActivePid ! {getView,From};
        {kill} ->
          %io:format("node ~p killed! ~n",[self()]),
          node_hub(ActivePid,PassivePid,false);
        {recover,_,From} -> From ! {alive};
        {timer,Counter} ->
          ActivePid ! {timer,Counter},
          node_hub(ActivePid,PassivePid,Alive);
        {push,BufferP,P} -> PassivePid ! {push, BufferP,P};
        {pull,BufferP,P} -> ActivePid ! {pull,BufferP,P};
        {update,NewView,passive} -> PassivePid ! {update,NewView};
        {update,NewView,active} -> ActivePid ! {update,NewView}
      end,
      node_hub(ActivePid,PassivePid,Alive);
    true ->
      receive
        {getView,From} ->
          From ! {ko},
          node_hub(ActivePid,PassivePid,Alive);
        {recover,NewView,From} ->
          %io:format("node ~p recover! ~n",[self()]),
          PassivePid ! {update,NewView},
          ActivePid ! {update,NewView},
          From ! {ok},
          node_hub(ActivePid,PassivePid,true)
      end
  end.

passive(State,H,S,C,PushPull,PeerS) ->
  receive
    {update,NewView} ->
      NewState = #state{id= State#state.id, pid = State#state.pid, buffer = [], view = NewView},
      passive(NewState,H,S,C,PushPull,PeerS);
    {push, BufferP, P} ->
      if
        PushPull ->
          PermutedView = permute(State#state.view),
          View = moveOldest(PermutedView,H),
          Buffer = lists:append([[0,State#state.pid]], lists:sublist(View, floor(abs(C/2-1)))),
          P ! {pull, Buffer, self()}
      end,
    View_select = select(C,H,S,BufferP,State#state.view,State#state.pid),
    NewView = increaseAge(View_select),
    NewState = #state{id = State#state.id, pid = State#state.pid, buffer = Buffer, view = NewView},
    State#state.pid ! {update,NewView,active},
    passive(NewState,H,S,C,PushPull,PeerS)
  end.

active(State,H,S,C,PushPull,T,PeerS) ->
  receive
    {getView, From} ->
      From ! {ok,State#state.view},
      active(State,H,S,C,PushPull,T,PeerS);
    {update,NewView} ->
      NewState = #state{id= State#state.id, pid = State#state.pid, buffer = [], view = NewView},
      active(NewState,H,S,C,PushPull,T,PeerS);
    {timer,Counter} ->
      io:format("log:: ~p ~p ~p~n", [State#state.pid, Counter, lists:map(fun([_,B]) -> B end,State#state.view)]),
      if
        State#state.view =/= [] ->
          if
            PeerS =:= tail ->
              Peer = lists:last(State#state.view);
            PeerS =:= rand ->
              Peer = lists:nth(rand:uniform(length(State#state.view)), State#state.view)
          end,
          PermutedView = permute(State#state.view),
          View = moveOldest(PermutedView,H),
          Buffer = lists:append([[0,State#state.pid]],lists:sublist(View, floor(abs(C/2-1)))),
          lists:last(Peer) ! {push,Buffer,self()},
          if
            PushPull ->
              receive
                {pull, BufferP, _} ->
                  View_select = select(C,H,S,BufferP,State#state.view,State#state.pid),
                  NewView = increaseAge(View_select),
                  NewState = #state{id = State#state.id,pid= State#state.pid, buffer = Buffer, view = NewView}
              after T ->
                  %io:format("TIMEOUT ~n"),
                  NewView = increaseAge(lists:delete(Peer,State#state.view)),
                  NewState = #state{id = State#state.id,pid= State#state.pid, buffer = Buffer, view = NewView}
              end;
            true ->
              NewView = increaseAge(State#state.view),
              NewState = #state{id= State#state.id, pid = State#state.pid, buffer = Buffer, view = NewView}
          end,
          State#state.pid ! {update,NewView, passive},
          active(NewState,H,S,C,PushPull,T,PeerS);
        true ->
          active(State,H,S,C,PushPull,T,PeerS)
    end
  end.

permute(View) ->
  shuffle(View).

shuffle(List) -> shuffle(List, []).

shuffle([], Acc) -> Acc;

shuffle(List, Acc) ->
{Leading, [H | T]} = lists:split(rand:uniform(length(List)) - 1, List),
shuffle(Leading ++ T, [H | Acc]).

moveOldest([],_,Acc) ->
  Acc;

moveOldest(View, 0, Acc) ->
  lists:append(View,Acc);

moveOldest(View,H,Acc) ->
  Oldest = lists:max(View),
  moveOldest(lists:delete(Oldest,View),H-1,lists:append([Oldest],Acc)).


moveOldest(PermutedView,H) -> moveOldest(PermutedView,H,[]).

remove_Oldest([],_) ->
  [];

remove_Oldest(View,0) ->
  View;

remove_Oldest(View,H) ->
  if H > 0 ->
      Oldest = lists:max(View),
      remove_Oldest(lists:delete(Oldest,View),H-1);
    true -> View
  end.

remove_Head(View,S) ->
  if S > 0 ->
      lists:nthtail(S,View);
    true -> View
  end.

remove_Random([],_) ->
  [];
remove_Random(View,0) ->
  View;
remove_Random(View,N) ->
  RandomElement = lists:nth(rand:uniform(length(View)), View),
  remove_Random(lists:delete(RandomElement,View),N-1).

remove_Dup(View) ->
  remove_Dup(View,View).

remove_Dup([],NewView) ->
  NewView;

remove_Dup([_],NewView) ->
  NewView;

remove_Dup([A|B],NewView) ->
  L = remove_Dup(B,A,NewView),
  if
    length(L) =:= length(NewView) ->
      remove_Dup(B,L);
    true ->
      remove_Dup(L,L)
  end.

remove_Dup([],_,Acc) ->
  Acc;

remove_Dup([A],C,Acc) ->
  X = lists:nth(2,A),
  Y = lists:nth(2,C),
  if
    X =:= Y ->
      lists:delete(A,Acc);
    true ->
      Acc
  end;

remove_Dup([A|B],C,Acc) ->
  X = lists:nth(2,A),
  Y = lists:nth(2,C),
  if
    X =:= Y ->
      remove_Dup(B,C,lists:delete(A,Acc));
    true ->
      remove_Dup(B,C,Acc)
  end.

remove_himself([],_,View) ->
  View;

remove_himself([A],Pid,View) ->
  X = lists:nth(2,A),
  if
    X =:= Pid ->
      lists:delete(A,View);
    true ->
      View
  end;

remove_himself([A|B],Pid,View) ->
  X = lists:nth(2,A),
  if
    X =:= Pid ->
      remove_himself(B,Pid,lists:delete(A,View));
    true ->
      remove_himself(B,Pid,View)
  end.


select(C,H,S,BufferP,View,Pid) ->
  View_append = lists:append(View, BufferP),
  View_no_dup = remove_Dup(View_append),
  View_remove_old = remove_Oldest(View_no_dup,min(H,length(View_no_dup)-C)),
  View_remove_head = remove_Head(View_remove_old,min(S,length(View_remove_old)-C)),
  View_remove_random = remove_Random(View_remove_head,max(0,length(View_remove_head)-C)),
  remove_himself(View_remove_random,Pid,View_remove_random).

increaseAge(View) ->
    lists:map(fun([A,B]) -> [A+1,B] end, View).

transform([],_,Acc) ->
  Acc;

transform([X],List,Acc) ->
  List ! {getPID,maps:get(id,X),self()},
  receive {pid,Pid} ->
    Neigh = [[0,Pid]],
    lists:append(Acc,Neigh)
  end;

transform([X|Y],List,Acc) ->
  List ! {getPID,maps:get(id,X),self()},
  receive {pid,Pid} ->
    Neigh = [[0,Pid]],
    transform(Y,List,lists:append(Acc,Neigh))
  end.


getNeigh(List,Id) ->
  List ! {getNeigh,Id,self()},
  receive
    {neigh,Neighbors} ->
      transform(Neighbors,List,[])
  end.
