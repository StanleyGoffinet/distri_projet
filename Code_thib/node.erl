- module(node).
- export([init/6,passive/6,active/6, permute/1,moveOldest/2,remove_Oldest/2,increaseAge/1]).
- record(state, {id, pid, buffer, view}).

init(Id, C, H, S, PushPull, PeerS) ->
  State = #state{id = Id, pid = self(), buffer = [], view = []},
  ActivePid = spawn(node, active, [State,H,S,C,PushPull,PeerS]),
  PassivePid = spawn(node, passive, [State,H,S,C,PushPull,PeerS]),
  node_hub(ActivePid,PassivePid).


node_hub(ActivePid,PassivePid) ->
  receive
    {kill} -> ActivePid ! {kill};
    {timer} -> ActivePid ! {timer};
    {push,BufferP,P} -> PassivePid ! {push, BufferP,P};
    {pull,BufferP,P} -> ActivePid ! {pull,BufferP,P};
    {update,NewState,passive} -> PassivePid ! {update,NewState};
    {update,NewState,active} -> ActivePid ! {update,NewState}
  end,
  node_hub(ActivePid,PassivePid).

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
    View_select = select(C,H,S,BufferP,State#state.view),
    NewView = increaseAge(View_select),
    NewState = #state{id = State#state.id, pid = State#state.pid, buffer = Buffer, view = NewView},
    State#state.pid ! {update,NewState,active},
    passive(NewState,H,S,C,PushPull,PeerS)
  end.

active(State,H,S,C,PushPull,PeerS) ->
  receive
    {update,NewView} ->
      NewState = #state{id= State#state.id, pid = State#state.pid, buffer = [], view = NewView},
      active(NewState,H,S,C,PushPull,PeerS);
    {timer} ->
      if
        PeerS =:= tail ->
          Peer = lists:last(lists:last(State#state.view));
        PeerS =:= rand ->
          Peer = lists:last(lists:nth(rand:uniform(length(State#state.view)-1), State#state.view))
      end,
      PermutedView = permute(State#state.view),
      View = moveOldest(PermutedView,H),
      Buffer = lists:append([[0,State#state.pid]],lists:sublist(View, floor(abs(C/2-1)))),
      Peer ! {push,Buffer,self()},
      if
        PushPull ->
          receive
            {pull, BufferP, P} ->
              View_select = select(C,H,S,BufferP,State#state.view),
              NewView = increaseAge(View_select),
              NewState = #state{id = State#state.id,pid= State#state.pid, buffer = Buffer, view = NewView}
          end;
        true ->
          NewView = increaseAge(State#state.view),
          NewState = #state{id= State#state.id, pid = State#state.pid, buffer = Buffer, view = NewView}
      end,
      State#state.pid ! {update,NewState, passive},
      active(NewState,H,S,C,PushPull,PeerS)
  end.

permute(View) ->
  shuffle(View).

shuffle(List) -> shuffle(List, []).

shuffle([], Acc) -> Acc;

shuffle(List, Acc) ->
{Leading, [H | T]} = lists:split(rand:uniform(length(List)) - 1, List),
shuffle(Leading ++ T, [H | Acc]).

moveOldest([],H,Acc) ->
  Acc;

moveOldest(View, 0, Acc) ->
  lists:append(View,Acc);

moveOldest(View,H,Acc) ->
  Oldest = lists:max(View),
  moveOldest(lists:delete(Oldest,View),H-1,lists:append([Oldest],Acc)).


moveOldest(PermutedView,H) -> moveOldest(PermutedView,H,[]).

remove_Oldest([],H) ->
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

remove_Random([],N) ->
  [];
remove_Random(View,0) ->
  View;
remove_Random(View,N) ->
  RandomElement = lists:nth(rand:uniform(length(View)-1), View),
  remove_Random(lists:delete(RandomElement,View),N-1).

select(C,H,S,BufferP,View) ->
  View_append = lists:append(View, BufferP),
  View_no_dup = lists:usort(View_append),
  View_remove_old = remove_Oldest(View_no_dup,min(H,length(View_no_dup)-C)),
  View_remove_head = remove_Head(View_remove_old,min(S,length(View_remove_old)-C)),
  remove_Random(View_remove_head,max(0,length(View_remove_head)-C)).

increaseAge(View) ->
    lists:map(fun([A,B]) -> [A+1,B] end, View).