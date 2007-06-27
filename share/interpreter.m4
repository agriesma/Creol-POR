dnl
dnl interpreter.m4 -- Source for modelchecker.maude and interpreter.maude
dnl
dnl Copyright (c) 2007
dnl
dnl The purpose of this file is to create the files `interpreter.maude'
dnl and `modelchecker.maude'.  These files have to be processed with
dnl m4, with either one of `CREOL' or `MODELCHECK' defined.
dnl
dnl See the lines below for its license
dnl
changecom
dnl
dnl The macro STEP is used to indicate that the specified transition
dnl may be both an equation (this is the case for model checking,
dnl or a rule (in the interpreter).
dnl $1 is the pre-condition of the rule.
dnl $2 is the post-condition of the rule.
dnl $3 is an annotation.  It must not be empty, and usually contains at
dnl    least the label.
define(`STEP',dnl
ifdef(`MODELCHECK',
`eq
  $1
  =
  $2
  $3 .',
`rl
  $1
  =>
  $2
  $3 .'))dnl
dnl
dnl The macro CSTEP is used to indicate that the specified transition
dnl may be both a conditional equation (this is the case for model checking),
dnl or a conditional rule (in the interpreter).
dnl $1 is the pre-condition of the rule.
dnl $2 is the post-condition of the rule.
dnl $3 is the condition.
dnl $4 is an annotation.  It must not be empty, and usually contains at
dnl    least the label.
define(`CSTEP',dnl
ifdef(`MODELCHECK',
`ceq
  $1
  =
  $2
  if $3
  $4 .',
`crl
  $1
  =>
  $2
  if $3
  $4 .'))dnl
dnl The usual header.
***
ifdef(`MODELCHECK',dnl
`*** Modelchecker for Creol.',dnl
`*** Reimplementation of the CREOL interpreter, 2007')
***
*** Copyright (c) 2007
***
*** Do NOT edit this file.  This file may be overwritten.  It has been
*** automatically generated from interpreter.m4 using m4.
***
*** This program is free software; you can redistribute it and/or
*** modify it under the terms of the GNU General Public License as
*** published by the Free Software Foundation; either version 2 of the
*** License, or (at your option) any later version.
***
*** This program is distributed in the hope that it will be useful, but
*** WITHOUT ANY WARRANTY; without even the implied warranty of
*** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*** General Public License for more details.
***
*** You should have received a copy of the GNU General Public License
*** along with this program; if not, write to the Free Software
*** Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
*** 02111-1307, USA.
***

ifdef(`MODELCHECK',`load model-checker')

*** Data types are in their own module.
in creol-datatypes .


***************************************************************************
***
*** Signature of programs and states.
***
***************************************************************************

*** Bound variables ***
fmod CREOL-SUBST is
  protecting EXT-BOOL .
  protecting CREOL-DATA-SIG .
  extending MAP{Vid, Data} * (sort Map{Vid, Data} to Subst,
                              op empty : -> Map{Vid, Data} to noSubst ) .

  vars A A' : Vid .
  vars D D' : Data .
  vars S1 S2  : Subst .

  *** Lazy composition operator for substitutions
  op _#_ : Subst Subst -> Subst .
  eq S1 # noSubst = S1 .
  eq noSubst # S2 = S2 .
  eq (S1 # S2)[ A ] = if dom(A, S2) then S2[A] else S1[A] fi .

  *** Composition operater for substitutions
  op compose : Subst Subst -> Subst .
  eq compose(S1, noSubst) = S1 .
  eq compose(noSubst, S1) = S1 .
  eq compose(S1, (S2, (A |-> D))) = compose(insert(A, D, S1), S2) .
  

  op dom : Vid Subst -> Bool .
  eq dom(A, S1 # S2) = dom(A, S2) or-else dom(A, S1) .
  eq dom(A, (S1, A |-> D)) = true .
  eq dom(A, S1) = false [owise] .
endfm

fmod `CREOL-EVAL' is

  protecting DATATYPES .
  protecting CREOL-SUBST .

  var D NOW : Data .
  var DL : DataList .
  vars E E' E'' : Expr .
  var EL : ExprList .
  var NeEL : NeExprList .
  var v : Vid .
  vars a c : String . *** XXX: Actually we want a : Aid, but we drop the class.
  var x : Lid .
  vars A L S : Subst .
  var F : String .
  var I : Int .
  var B : Bool .

  sorts Aid Lid .
  subsort Aid < Vid .
  subsorts String < Lid < Vid .
  op _@@_ : String String -> Aid [ctor prec 31] .



ifdef(`TIME', `dnl
define(EVAL, ``eval' ($1, $2, $3)')dnl
define(EVALLIST, `evalList ($1, $2, $3)')dnl

  *** Third component is the value of now.
  op eval : Data Subst Data -> Data .
  op eval : Expr Subst Data -> Data .
  op evalList : DataList Subst Data -> DataList .
  op evalList : ExprList Subst Data -> DataList .

  *** Substitute the expression now by its value.
  eq `eval' (now, S, NOW) = NOW .
',`dnl
dnl This upper case eval and evalList macros map to the binary version
dnl (untimed) .
define(EVAL, `eval ($1, $2)')dnl
define(EVALLIST, `evalList ($1, $2)')dnl
  op eval : Data Subst -> Data .
  op eval : Expr Subst -> Data .
  op evalList : DataList Subst -> DataList .
  op evalList : ExprList Subst -> DataList .
')
  eq EVAL(D, S, NOW) = D .

  *** standard evaluation of expression
  eq EVAL((a @@ c), (A # L), NOW) =  A [a] .
  eq EVAL(x, (A # L), NOW) =  L [x] [nonexec] . *** XXX: Later
  eq EVAL(v, S, NOW) =  S [v] .
  eq EVAL(F (EL), S, NOW) = F ( evalList(EL, S) ) .
  eq EVAL(list(EL), S, NOW) = list(evalList(EL, S)) .
  eq EVAL(pair(E,E'),S, NOW) = pair(`eval'(E,S),`eval'(E',S)) .
  eq EVAL(setl(EL), S, NOW) = setl(evalList(EL, S)) .

  eq EVALLIST(emp, S, NOW) = emp .
  eq EVALLIST(DL, S, NOW)= DL .

  eq EVALLIST(E , S, NOW) = EVAL(E, S, NOW) .
  eq EVALLIST(E # NeEL, S, NOW) =
    EVAL(E, S, NOW) # EVALLIST(NeEL, S, NOW) .

  *** multi-way conditional expression
  sorts Case NeCases Cases .
  subsorts Case < NeCases < Cases .
  op of_wh_do_ : Expr Expr Expr -> Case [ctor `format' (b o b o b o d)] .
  op noCase : -> Cases [ctor] .
  op _|_ : Case Case -> NeCases [ctor assoc id: noCase] .
  op case__ : Expr Cases -> Expr [ctor] .
  op case__ : Data Cases -> Data [ditto] .

  var C : Cases .

  eq EVAL(case E noCase, S, NOW) = null .
  eq EVAL(case D ((of E wh E' do E'') | C), S, NOW) =
    if EVAL(E, S, NOW) == D then
      EVAL(E'', S, NOW)
    else
      EVAL(case D C, S, NOW)
    fi .
  eq EVAL(case E C, S, NOW) = case EVAL(E, S, NOW) C [owise] .
endfm


fmod CREOL-GUARDS is
  protecting `CREOL-EVAL' .

  sorts NoGuard Guard Return PureGuard . 
  subsorts Return Expr < PureGuard .
  subsorts NoGuard PureGuard < Guard .

  vars E E' : Expr .
  var PG : PureGuard .

  op noGuard : -> NoGuard [ctor `format' (b o)] .
  op _??  : Vid -> Return [ctor] .
  op _??  : Label -> Return [ctor] .

endfm

fmod CREOL-STATEMENT is
  pr CREOL-GUARDS .

  *** SuspStm is a statement which can be suspended.  It includes
  *** await, [] and ||| (the later two defined in CREOL-STM-LIST.
  sorts Mid Cid Stm SuspStm .
  subsort SuspStm < Stm .
  subsort String < Cid .
  subsort String < Mid .

  op _._ : Expr String -> Mid [ctor prec 33] .
  op _@_ : String Cid -> Mid [ctor prec 33] .

  op skip : -> Stm [ctor] .
  op release : -> Stm [ctor] .
  op _::=_ : VidList ExprList -> Stm [ctor prec 39] .
  op _::= new_(_) : Vid Cid ExprList -> Stm [ctor prec 37 `format' (d b d o d d d d)] .
  op _!_(_) : Vid Mid ExprList -> Stm [ctor prec 39] .
  op _?(_)  : Vid VidList -> Stm [ctor prec 39] .
  op _?(_)  : Label VidList -> Stm [ctor prec 39] .
  op await_ : Guard    -> SuspStm [ctor] .
  op return : ExprList -> Stm [ctor `format' (c o)] .
  op bury : VidList -> Stm [ctor `format' (c o)] .
  op free : VidList -> Stm [ctor `format' (c o)] .
  op cont : Label -> Stm [ctor `format' (c o)] .
  op tailcall_(_) : Mid ExprList -> Stm [ctor `format' (c o c o c o)] .
  op accept : Label -> Stm [ctor `format' (c o)] .

  *** multiple assignment
  ***
  *** For the model checker the following will be evaluated as an
  *** equation and the old rule is not confluent.

  op _assign_ : VidList DataList -> Stm [ctor `format' (d c o d)] .

endfm

view Stm from TRIV to CREOL-STATEMENT is
   sort Elt to Stm .
endv

fmod CREOL-STM-LIST is
  pr CREOL-STATEMENT .                
  protecting LIST{Stm} * (sort List{Stm} to StmList,
                          sort NeList{Stm} to NeStmList,
			  op nil : -> List{Stm} to noStm,
			  op __ : List{Stm} List{Stm} -> List{Stm} to _;_ [`format' (d r o d)]) .

  op if_th_el_fi : Expr NeStmList NeStmList -> Stm [ctor] . 
  op while_do_od : Expr NeStmList -> Stm [ctor] .
  op _[]_  : NeStmList NeStmList -> SuspStm [ctor comm assoc prec 45 `format' (d r d o d)] .
  op _|||_ : NeStmList NeStmList -> SuspStm [ctor comm assoc prec 47 `format' (d r o d)] .
  op _MERGER_  : StmList StmList -> Stm [assoc] .

  var SL : StmList .
  var NeSL : NeStmList .
  var AL : VidList .
  var DL : DataList .
  var EL : ExprList .
  var B : Expr .
  var PG : PureGuard .

  *** Some simplifications:
  eq noStm MERGER SL = SL .
  eq SL MERGER noStm = SL .
  eq await noGuard ; NeSL = NeSL .

  *** Optimize assignments.  This way we save reducing a skip.  Also note
  *** that the empty assignment is /not/ programmer syntax, it is inserted
  *** during run-time.
  eq (noVid assign emp) = noStm .
  eq (noVid ::= emp) = noStm .

  sort Process .
  op idle : -> Process [`format' (!b o)] .  
  op _,_ : Subst StmList -> Process [ctor `format' (o r sbu o)] . 
  var L : Subst .
  eq (L, noStm) = idle . *** if ".label" is needed this is dangerous!
  eq idle = (noSubst, noStm) [nonexec metadata "Will cause infinite loops."] .


  sorts NeMProc MProc .
  subsort Process < NeMProc < MProc .    *** Multiset of Processes
  op noProc : -> MProc [ctor] .
  op _++_ : MProc MProc -> MProc [ctor assoc comm id: noProc prec 41 `format' (d r os d)] .
  op _++_ : NeMProc MProc -> NeMProc [ctor ditto] .
  op _++_ : MProc NeMProc -> NeMProc [ctor ditto] .

endfm

*** CREOL classes ***
fmod CREOL-CLASS is
  protecting CREOL-STM-LIST .

  sorts    Class Mtd MMtd Inh InhList NeInhList . *** inheritance list
  subsorts Inh < NeInhList < InhList .

  op  _<_> : Cid  ExprList -> Inh [ctor prec 15] . *** initialised superclass
  op noInh : -> InhList [ctor] .
  op  _##_   : InhList InhList -> InhList [ctor assoc id: noInh] .

  var Ih : Inh . 
  var IL : InhList .
  var S : Subst . 
  var SL : StmList . 
  var MM : MMtd .
  var EL : ExprList .
  var O : Oid .
  var N : Nat .
  var AL : VidList .
  vars Q Q' : String .

  *** XXX: This looks dangerous or confusing for programmers.
  *** Why not: Ih ## IL ## Ih = IL ## Ih to have Ih initialised last?

  eq  Ih ## IL ## Ih = Ih ## IL .

  op <_: Mtdname | Param:_, Latt:_, Code:_> : 
    String VidList Subst StmList -> Mtd [ctor
      `format' (b d o d d sb o d sb o d sb o b o)] .

  subsort Mtd < MMtd .    *** Multiset of methods

  op noMtd : -> Mtd [ctor] .
  op _*_  : MMtd MMtd -> MMtd [ctor assoc comm id: noMtd `format' (d d ni d)] .

  op <_: Cl | Inh:_, Par:_, Att:_, Mtds:_, Ocnt:_> : 
    Cid InhList VidList Subst MMtd Nat -> Class 
     [`format' (ng d o d d  sg o d  sg o d  sg o d  sg++ oni o  gni o-- g o)] .

  op emptyClass : -> Class .
  eq emptyClass =
    < "NoClass" : Cl | Inh: noInh , Par: noVid, Att: noSubst, Mtds: noMtd ,
      Ocnt: 0 > .

  *** Class/method functions ***
  op get : String MMtd Oid Label ExprList -> Process .  *** fetches pair (code, vars)
  op _in_ : String MMtd -> Bool .  *** checks if Q is a declared 
                                *** method in the method multiset

  eq Q in noMtd = false .
  eq Q in (< Q' : Mtdname | Param: AL, Latt: S, Code: SL > * MM) = 
       if (Q == Q') then true else (Q in MM) fi .

  *** bind call to process
  var Lab : Label .
  eq get(Q, noMtd, O, Lab, EL) = noProc . 
  eq get(Q, < Q' : Mtdname | Param: AL, Latt: S, Code: SL > * MM, O, Lab, EL) = 
    if Q == Q' 
    then (insert("caller", O, insert(".label", Lab, S)), (AL ::= EL) ; SL)
    else get(Q, MM, O, Lab, EL) fi .

endfm

*** CREOL objects ***
fmod CREOL-OBJECT is
  protecting CREOL-CLASS .

  sort Object .

  op <_:_ | Att:_, Pr:_, PrQ:_, Lcnt:_> : 
       Oid Cid Subst Process MProc Nat -> Object 
         [ctor `format' (nr d d g r d o  r++ ni o  r ni o  r s o--  r o)] .

  op noObj : -> Object [ctor] .

endfm

*** CREOL messages and queues ***
fmod CREOL-COMMUNICATION is
  protecting CREOL-OBJECT .

  sort Labels . *** list of labels
  subsort Label < Labels .

  sorts Body Msg MMsg Kid Queue .
  subsort Body < MMsg .

  op noMsg : -> MMsg [ctor] .
  op _+_ : MMsg MMsg -> MMsg [ctor assoc comm id: noMsg] . 

  op size : MMsg -> Nat .
  var M : Body .
  var MB : MMsg .
  eq size(M + MB) = 1 + size(MB) .
  eq size(noMsg) = 0 .

  *** INVOCATION and REPLY
  op invoc(_,_,_,_) : *** Nat Oid 
  Oid Label Mid DataList -> Body [ctor `format' (! o o o o o o o o o o)] .  
  op comp(_,_) : Label DataList -> Body [ctor `format' (! o o o o o o)] .  

  op _from_to_ : Body Oid Oid -> Msg [ctor `format' (o ! o ! o on)] .
  op error(_) : String -> [Msg] [ctor `format' (nnr r o! or onn)] .     *** error 
  op warning(_) : String -> [Msg] [ctor `format' (nnr! r! r! or onn)] .   *** warning 

  *** Method binding messages
  op bindMtd : Oid Oid Label String ExprList InhList -> Msg [ctor] . 
  ***Bind method request
  *** Given: caller callee method params (list of classes to look in)
  op boundMtd(_,_) : Oid Process -> Msg 
    [ctor `format' (!r r o o o !r on)] . *** binding result
  *** CONSIDER the call O.Q(I). bindMtd(O,Q,I,C S) trie to find Q in
  *** class C or superclasses, then in S. boundMtd(O,Mt) is the result.


  *** message queue
  op noDealloc :         -> Labels  [ctor] .
  op _^_ : Labels Labels -> Labels [ctor comm assoc id: noDealloc] .

  op noQu : -> Queue [ctor] .
  op <_: Qu | Size:_, Dealloc:_, Ev:_ > : Oid Nat Labels MMsg -> Queue 
                          [`format' (nm r o d d sm o d sm o d sm o m o)] .

endfm

*** STATE CONFIGURATION ***
fmod CREOL-CONFIG is
  protecting CREOL-COMMUNICATION .

  sort Configuration .

  subsorts Object Msg Queue Class < Configuration .

  op noConf : -> Configuration [ctor] .
  op __ : Configuration Configuration -> Configuration
	[ctor assoc comm id: noConf `format' (d n d)] .

  *** Useful for real-time maude and some other tricks.
ifdef(`MODELCHECK',dnl
  *** Maude's model checker asks us to provide State.
  including SATISFACTION .
  including MODEL-CHECKER .
,dnl
  *** In the interpreter we define our own sort state.
  sort State .
)dnl

  op {_} : Configuration -> State [ctor] .

  *** System initialisation
  var C : Cid .
  var E : ExprList .
  op main : Cid ExprList -> Configuration .
  eq main(C,E) = < ob("main") : "NoClass" | Att: noSubst, 
                 Pr: (noSubst, ("var" ::= new C(E))), PrQ: noProc, Lcnt: 0 > 
               < ob("main") : Qu | Size: 1, Dealloc: noDealloc,Ev: noMsg > .

endfm

*** AUXILIARY FUNCTIONS ***
fmod CREOL-AUX-FUNCTIONS is

  protecting CREOL-CONFIG .
  protecting CONVERSION .

  vars N N' : Nat .
  vars L L' : Label .
  vars E E' : Expr .
  var EL : ExprList .
  var A : Vid .
  var Q : String .
  vars G1 G2 : Guard .
  var S : Subst .
  var MM : MMsg .
  var C : Cid .

  *** Create a new fresh name for an object.
  op newId : Cid Nat -> Oid .
  eq newId(C, N)  = ob(C + string(N,10)) .

  *** Check if a message is in the queue.
  op inqueue  : Label MMsg -> Bool .
  eq inqueue(L, noMsg) = false .
  eq inqueue(L, MM + comp(L', EL)) =
	if L == L' then true else inqueue(L, MM) fi .

  op enabledGuard : Guard Subst MMsg -> Bool .
  eq enabledGuard(noGuard, S, MM) = true .
  eq enabledGuard(E, S, MM) = EVAL(E, S, NOW) asBool .
  eq enabledGuard((A ??), S, MM) = inqueue(S[A], MM) .
  eq enabledGuard((L ??), S, MM) = inqueue(L, MM) .

  vars  ST ST' : Stm . 
  vars SL SL' SL'' : StmList . 
  vars NeSL NeSL' NeSL'' : NeStmList .
  var AL : VidList .

  op enabled : NeStmList Subst MMsg -> Bool .
  eq enabled((NeSL [] NeSL') ; SL'',  S, MM) =
       enabled(NeSL, S, MM) or enabled(NeSL', S, MM) .
  eq enabled((NeSL ||| NeSL') ; SL'', S, MM) =
       enabled(NeSL, S, MM) or enabled(NeSL', S, MM) .
  eq enabled((NeSL MERGER SL') ; SL'', S, MM) = enabled(NeSL, S, MM) .
  eq enabled(await G1 ; SL'', S, MM) = enabledGuard(G1,S,MM) .
  eq enabled(NeSL, S, MM) = true [owise] .

  *** The ready predicate holds, if a statement is ready for execution,
  *** i.e., the corresponding process may be waken up.
  op ready : NeStmList Subst MMsg -> Bool . *** eval guard 
  eq ready((NeSL [] NeSL') ; SL'', S, MM) =
        ready(NeSL, S, MM) or ready(NeSL', S, MM) .
  eq ready((NeSL ||| NeSL') ; SL'', S, MM) =
	ready(NeSL, S, MM) or ready(NeSL', S, MM) .
  eq ready((NeSL MERGER SL') ; SL'', S, MM) = ready(NeSL, S, MM) .
  eq ready((A ?(AL)) ; SL'' , S, MM) = inqueue(S[A], MM) . 
  eq ready((L ?(AL)) ; SL'' , S, MM) = inqueue(L, MM) . 
  eq ready(NeSL, S, MM) = enabled(NeSL, S, MM) [owise] .

endfm

*** THE MACHINE ***
mod ifdef(`MODELCHECK',CREOL-MODEL-CHECKER,CREOL-INTERPRETER) is

  extending CREOL-DATA-SIG .

  protecting CREOL-AUX-FUNCTIONS .

  vars O O' : Oid .
  vars C C' : Cid .
  vars A A' : Vid .
  var a : String .
  var AL : VidList .
  var NeAL : NeVidList .
  var D : Data .
  var DL : DataList .
  var NeDL : NeDataList .
  vars E E' : Expr .
  vars EL EL' : ExprList .
  vars NeEL NeEL' : NeExprList .
  var ST : Stm .
  var SuS : SuspStm .
  vars SL SL' SL'' : StmList .
  vars NeSL NeSL' : NeStmList .
  vars P P' : Process .
  var W : MProc .
  vars S S' L L' : Subst .
  vars N F Sz : Nat .
  vars I I' : InhList .
  var MS : MMtd .
  vars Lab Lab' : Label .
  var LS : Labels .
  var MM : MMsg .
  var G : Guard .
  var M : Mid .
  var Q : String .
  var MsgBody : Body .
  var cnf : Configuration .

ifdef(`MODELCHECK',dnl
  op label : Oid Oid Mid DataList -> Label [ctor] .
  eq caller(label(O, O', M, DL)) = O . 
,dnl
 op label(_,_) : Oid Nat -> Label [ctor ``format'' (d d ! d d o d)] .
 eq caller(label(O, N)) = O .
)dnl

*** Evaluate all arguments.
STEP(dnl
`< O : C | Att: S, Pr: (L, AL ::= EL ; SL),
	    PrQ: W, Lcnt: N >',
`< O : C | Att: S, Pr: (L,((AL assign EVALLIST(EL, (S # L), NOW)); SL)), 
	    PrQ: W, Lcnt: N >',
`[label assign]')

*** XXX: This equation is currently broken (matches any class, etc.)
*** The correct implementation depends on the type inference.
*** But we know that if we refer to A statically, then it should be
*** an attribute.
eq
  < O : C | Att: S, Pr: (L,( ((a @@ C'), AL assign D # DL) ; SL)),
    PrQ: W, Lcnt: N >
  =
    < O : C | Att: insert(a, D, S), Pr: (L, (AL assign DL) ; SL), PrQ: W,
      Lcnt: N > 
  [label do-static-assign] .


*** Assign the value.
***
*** Testing for a of sort string is necessary for confluence, because
*** 'A == a @ C' is neither in S nor in L.
***
*** The "buggy" version seems to do the right thing and is slightly faster.

eq
  < O : C | Att: S, Pr: (L,( (a , AL assign D # DL) ; SL)), PrQ: W,
    Lcnt: N >
  =
  if dom(a,S) then
    < O : C | Att: insert(a, D, S), Pr: (L, (AL assign DL) ; SL), PrQ: W,
      Lcnt: N > 
  else
    < O : C | Att: S, Pr: (insert(a, D, L), (AL assign DL) ; SL), PrQ: W,
      Lcnt: N > 
  fi
  [label do-assign] .



*** Skip
STEP(dnl
`< O : C | Att: S, Pr: (L, skip ; SL), PrQ: W, Lcnt: N >',
`< O : C | Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >',
`[label skip]')


*** if_then_else ***
STEP(dnl
< O : C | Att: S`,' Pr: (L`,' if E th SL' el SL'' fi ; SL)`,' PrQ: W`,' Lcnt: N >,
if EVAL(E, (S # L), NOW) asBool then
    < O : C | Att: S`,' Pr: (L`,' SL' ; SL)`,' PrQ: W`,' Lcnt: N >
  else
    < O : C | Att: S`,' Pr: (L`,' SL'' ; SL)`,' PrQ: W`,' Lcnt: N >
  fi,
`[label if-th]')

*** while ***
*** During model checking we want to be able to observe infinite loops.
*** Therefore, this has to be a rule.
rl
  < O : C | Att: S, Pr: (L, while E do SL od ; SL'), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S,
            Pr: (L, (if E th (SL ; while E do SL od) el skip fi); SL'),
            PrQ: W, Lcnt: N >
  [label while]
  .

*** OBJECT CREATION
***
*** Using synchronous calls does not work for the model checker.
*** Expanding "init" (emp ; noVid) needs a label value, which we do
*** not have.  We reserve a label for our purposes.
STEP(dnl
< O : C | Att: S`,'Pr: (L`,' (A ::= new C' (EL)); SL)`,'PrQ: W`,' Lcnt: N > 
  < C' : Cl | Inh: I `,' Par: AL`,' Att: S' `,' Mtds: MS `,' Ocnt: F >,
< O : C | Att: S`,' Pr: (L`,' (A assign newId(C'`,' F)); SL)`,' PrQ: W`,' Lcnt: N >
  < C' : Cl | Inh: I `,' Par: AL`,' Att: S' `,' Mtds: MS `,' Ocnt: (F + 1) >
  < newId(C'`,'F) : C' | Att: S`,' Pr: idle`,' PrQ: noProc`,' Lcnt: 1 >
  < newId(C'`,'F) : Qu | Size: 10`,' Dealloc: noDealloc`,' Ev: noMsg > *** XXX: Currently hard-coded.
  findAttr(newId(C'`,'F)`,' I`,' S'`,' 
    (AL assign EVALLIST(EL, compose(S`,'  L), NOW))`,'
    ((noSubst`,' (".init" ! "init" (emp)) ; (".init" ?(noVid)) ; (".run" ! "run" (emp)) ; (".run" ?(noVid))))),
`[label new-object]')


*** ATTRIBUTE inheritance with multiple inheritance
*** CMC assumes that all attributes names are (globally) different.
*** For the purpose of the CMC the class parameters are treated as
*** attributes!

op findAttr  : Oid InhList Subst StmList Process -> Msg [ctor `format' (n d)] .
op foundAttr : Oid Subst  StmList Process -> Msg [ctor `format' (n d)] .

eq findAttr(O, noInh, S, SL, P) = foundAttr(O, S, SL, P) .

*** Good thing we cannot use class names as variables in (at least in
*** the source language.  The name of the class will be used as the
*** name of the variable used to call the init routine.
***
*** The initialisation of the attributes is ordered from class to
*** super-class, because we want to pass on the class parameters to
*** the super-class.  The initialisation, i.e., calling the init method,
*** is done from the super classes to the sub-classes, making sure that
*** the state of the object at the beginning of the init call is in a
*** consistent state.
eq
  findAttr(O,(C < EL > `##' I), S, SL, (L', SL')) 
  < C : Cl | Inh: I', Par: AL, Att: S', Mtds: MS, Ocnt: F >
  =
  findAttr(O, I ## I', compose(S', S),
           SL ; (AL ::= EL), 
           (L', (".init" ! "init" @ C(emp)) ; (".init" ?( noVid)) ; SL'))
  < C : Cl | Inh: I', Par: AL, Att: S', Mtds: MS, Ocnt: F >
  [label find-attr]
  .

eq
  foundAttr(O, S', SL, (L', SL'))
  < O : C | Att: S, Pr: idle, PrQ: W, Lcnt: N >
  =
  < O : C | Att: ("this" |-> O, S'), Pr: (L', SL ; SL'), PrQ: W, Lcnt: N >
  .





*** Non-deterministic choice ***
*** Choice is comm, so [nondet] considers both NeSL and NeSL'.
crl
  < O : C | Att: S, Pr: (L, (NeSL [] NeSL'); SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =>
  < O : C | Att: S, Pr: (L, (NeSL ; SL)), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  if ready(NeSL, (S # L), MM)
  [label nondet]
  .




*** Merge ***
*** Merge is comm, so [merge] considers both NeSL and NeSL'.
crl
  < O : C | Att: S, Pr: (L, (NeSL ||| NeSL'); SL), PrQ: W, Lcnt: N >  
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =>
  < O : C | Att: S, Pr: (L, (NeSL MERGER NeSL'); SL), PrQ: W, Lcnt: N >  
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  if ready(NeSL,(S # L), MM)
  [label merge]
  .

*** MERGER
***
eq
  < O : C | Att: S,  Pr:  (L, ((ST ; SL') MERGER NeSL'); SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =
  if enabled(ST, (S # L), MM) then
    < O : C | Att: S, Pr: (L, ((ST ; (SL' MERGER NeSL')); SL)), PrQ: W,
      Lcnt: N >
  else
    < O : C | Att: S, Pr: (L, ((ST ; SL') ||| NeSL'); SL), PrQ: W, Lcnt: N >   
  fi
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  [label merge-aux]
  .



*** local call
ceq
  < O : C | Att: S, Pr: (L, ((Lab ?(AL)); SL)),
            PrQ: (L', SL') ++ W, Lcnt: F >
  = 
  < O : C | Att: S, Pr: (L', (SL' ; cont(Lab))),
            PrQ: (L, ((Lab ?(AL)); SL)) ++ W, Lcnt: F >
  if L'[".label"] == Lab
  [label local-call]
  .


*** Suspension ***

*** The release statement is an unconditional processor release point.
STEP(dnl
`< O : C | Att: S, Pr: (L, release ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
`< O : C | Att: S, Pr: idle, PrQ: (L, SL) ++ W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
`[label release]')


*** Suspend a process.
CSTEP(dnl
`< O : C | Att: S, Pr: (L, SuS ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
`< O : C | Att: S, Pr: idle, PrQ: (L, SuS ; SL) ++ W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
`not enabled(SuS, (S # L), MM)',
`[label suspend]')


*** Guards ***

*** Optimze label access in await statements.
eq
  < O : C | Att: S, Pr: (L, await (A ??) ; SL), PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: (L, await ((L[A]) ??) ; SL), PrQ: W, Lcnt: N >
  .

CSTEP(dnl
`< O : C | Att: S, Pr: (L, await G ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
`< O : C | Att: S, Pr: (L,SL) , PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM > ',
`enabledGuard(G, (S # L), MM)',
`[label guard]')




*** Schedule a new process for execution

*** Select a new process, if it is ready.
***
*** Must be a rule, also in the interpreter.
crl
  < O : C | Att: S, Pr: idle, PrQ: (L, SL) ++ W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =>
  < O : C | Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  if ready(SL, (S # L), MM)
  [label PrQ-ready]
  .


***
*** Tail calls.
***
*** Fake the caller and the label and tag the label.  Since we do not
*** want to interleave, this can also be an equation.
STEP(`< O : C | Att: S, Pr: (L, tailcall M(EL) ; SL), PrQ: W, Lcnt: N >',
`< O : C | Att: S, Pr: (noSubst, accept(tag(L[".label"]))), PrQ: W, Lcnt: N >
 bindMtd(O, O, tag(L[".label"]), M, EVALLIST(EL, (S # L), NOW), C < emp >)
',
`[label tailcall]')

*** If we receive the method body, the call is accepted and the label untagged.
crl
  < O : C | Att: S, Pr: (noSubst, accept(Lab)), PrQ: (L, SL) ++ W,
         Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert(".label", tag(Lab), L), SL), PrQ: W, Lcnt: N >
  if L[".label"] = Lab
  [label tailcall-accept]
  .





*** METHOD CALLS ***

*** receive invocation message ***
STEP(< O : C | Att: S`,' Pr: P`,' PrQ: W`,' Lcnt: N >
  < O : Qu | Size: Sz`,' Dealloc: LS`,' Ev: MM + invoc(O'`,' Lab`,' Q`,' DL) >
,
< O : C | Att: S`,' Pr: P`,' PrQ: W`,' Lcnt: N >
  < O : Qu | Size: Sz`,' Dealloc: LS`,' Ev: MM >
	 bindMtd(O`,' O'`,' Lab`,' Q`,' DL`,' C < emp >),
`[label receive-call-req]')


*** Method binding with multiple inheritance

*** If we do not find a run method we provide a default method.
eq
  bindMtd(O, O', Lab, "run", EL, noInh)
  = 
  boundMtd(O,(("caller" |-> O', ".label" |-> Lab), return(emp)))
  .

*** Same for init.
eq
  bindMtd(O, O', Lab, "init", EL, noInh)
  = 
  boundMtd(O,(("caller" |-> O', ".label" |-> Lab), return(emp)))
  .


eq
  bindMtd(O, O', Lab, M, EL, (C < EL' >) `##' I')
  < C : Cl | Inh: I , Par: AL, Att: S , Mtds: MS , Ocnt: F >
  =
  if (M in MS) then
    boundMtd(O,get(M, MS, O', Lab, EL))
  else
    bindMtd(O, O', Lab, M, EL, I `##' I')
  fi 
  < C : Cl | Inh: I , Par: AL, Att: S , Mtds: MS , Ocnt: F >
  .

STEP(< O : Qu | Size: Sz`,' Dealloc: LS`,'
                  Ev: MM + invoc(O'`,' Lab`,' Q @ C`,' DL) >,
< O : Qu | Size: Sz`,' Dealloc: LS`,' Ev: MM >
    bindMtd(O`,' O'`,' Lab`,' Q`,' DL`,' C < emp >),
`[label receive-call-req]')

eq
  boundMtd(O, P')
  < O : C | Att: S, Pr: P, PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: P, PrQ: P' ++ W, Lcnt: N >
  [label receive-call-bound]
  .

rl
  < O : C | Att: S, Pr: (L, (cont(Lab); SL)),
	    PrQ: (L',((Lab)?(AL); SL')) ++ W, Lcnt: F >
  =>
  < O : C | Att: S, Pr: (L', ((Lab)?(AL); SL')), PrQ: W, Lcnt: F >
  [label continue]
  .


ifdef(`MODELCHECK',
`***(
    The size of the queue is limited in the model checker, and we will
    therefore check whether there is room for the message in the queue,
    before sending.
  )***
  eq
  < O : C | Att: S, Pr: (L, (A ! Q(EL)); SL), PrQ: W, Lcnt: F >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  =
  < O : C | Att: S, Pr: (insert(A, label(O, O, Q, EVALLIST(EL, (S # L), NOW)), L), SL), PrQ: W, Lcnt: F >
  *** XXX: QUEUE
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM +
    invoc(O, label(O, O, Q, EVALLIST(EL, (S # L), NOW)), Q, EVALLIST(EL, (S # L), NOW)) >
  *** if size(MM) < Sz
',dnl
`rl
  < O : C | Att: S, Pr: (L, (A ! Q(EL)); SL), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert(A, label(O, N), L), SL), PrQ: W, Lcnt: N + 1 >
  invoc(O, label(O, N), Q, EVALLIST(EL, (S # L), NOW)) from O to O
')dnl
  [label local-async-reply]
  .

ifdef(`MODELCHECK',dnl
eq
  < O : C | Att: S`,' Pr: (L`,' ( A ! Q @ C'(EL)); SL)`,' PrQ: W`,' Lcnt: N >
  =
  < O : C | Att: S`,' Pr: (insert(A`,' label(O`,' O`,' Q`,' EVALLIST(EL, (S # L), NOW))`,' L)`,' SL)`,' PrQ: W`,' Lcnt: N >
  invoc(O`,' label(O`,'O`,'Q @ C'`,' EVALLIST(EL, (S # L), NOW))`,' Q @ C'`,'
        EVALLIST(EL, (S # L), NOW)) from O to O
,dnl
rl
  < O : C | Att: S`,' Pr: (L`,' ( A ! Q @ C'(EL)); SL)`,' PrQ: W`,' Lcnt: N >
  =>
  < O : C | Att: S`,' Pr: (insert (A`,' label(O`,' N)`,' L)`,' SL)`,' PrQ: W`,'
    Lcnt: N + 1 >
  invoc(O`,' label(O`,' N)`,' Q @ C'`,' EVALLIST(EL, (S # L), NOW)) from O to O
)dnl
  [label local-async-qualified-req]
  .

ifdef(`MODELCHECK',
`eq
  < O : C | Att: S, Pr: (L, (A ! E . Q(EL)); SL), PrQ: W, Lcnt: N >
  =
  < O : C | Att: S, Pr: (insert(A, label(O, EVAL(E, (S # L), NOW), Q, EVALLIST(EL, (S # L), NOW)), L), SL), PrQ: W, Lcnt: N >
  invoc(O, label(O, EVAL(E, (S # L), NOW), Q, EVALLIST(EL, (S # L), NOW)), Q, EVALLIST(EL, (S # L), NOW))
    from O to EVAL(E, (S # L), NOW)
',dnl
`rl
  < O : C | Att: S, Pr: (L, (A ! E . Q(EL)); SL), PrQ: W, Lcnt: N >
  =>
  < O : C | Att: S, Pr: (insert(A, label(O, N), L), SL), PrQ: W, Lcnt: N + 1 >
  invoc(O, label(O, N), Q , EVALLIST(EL, (S # L), NOW)) from O to EVAL(E, (S # L), NOW)
')dnl
  [label remote-async-reply]
  .

*** emit reply message ***
STEP(`< O : C |  Att: S, Pr: (L, (return(EL)); SL), PrQ: W, Lcnt: N >',
`< O : C |  Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >
  comp(L[".label"], EVALLIST(EL, (S # L), NOW)) from O to caller(L[".label"])',
`[label return]')

*** Optimization: reduce label to value only once
eq
  < O : C |  Att: S, Pr: (L, (A ?(AL)); SL), PrQ: W, Lcnt: N > 
  =
  < O : C |  Att: S, Pr: (L, ((L[A]) ?(AL)); SL), PrQ: W, Lcnt: N > .


*** Model checker behaves differently from interpreter in that receiving
*** and freeing of label variables will set the variable containing this
*** name to null.  This will save us some states.  In the model checker
*** it is /guaranteed/ that exactly one variable exists, which holds the
*** label value,
eq
  < O : C |  Att: S,
    Pr: ((ifdef(`MODELCHECK', `A |-> Lab, L', L)),
         (Lab ? (AL)); SL), PrQ: W, Lcnt: F > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + comp(Lab, DL) >
  = 
  < O : C |  Att: S,
    Pr: ((ifdef(`MODELCHECKER', `A |-> noLabel, L', L)),
         (AL assign DL); SL), PrQ: W, Lcnt: F > 
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  [label receive-reply]
  .

*** Transport rule: include new message in queue
eq
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM > (MsgBody from O' to O)
  =
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM + MsgBody >
  [label transport]
  .

*** Free a label.  Make sure that the use of labels is linear.
STEP(`< O : C | Att: S, Pr: ((A |-> Lab, L), free(A) ; SL), PrQ: W, Lcnt: N >
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >',
  `< O : C | Att: S, Pr: ((A |-> ifdef(`MODELCHECKER', noLabel, Lab), L), SL),
              PrQ: W, Lcnt: N > 
  < O : Qu | Size: Sz, Dealloc: (Lab ^ LS), Ev: MM >',
  `[label free]')

*** Deallocate
eq
  < O : Qu | Size: Sz, Dealloc: (Lab ^ LS), Ev: comp(Lab , DL) + MM >
  =
  < O : Qu | Size: Sz, Dealloc: LS, Ev: MM >
  [label deallocate] .

*** Bury a variable

eq
  < O : C | Att: S, Pr: ((L, (A |-> D)), bury(A) ; SL), PrQ: W, Lcnt: N > =
  < O : C | Att: S, Pr: (L, SL), PrQ: W, Lcnt: N >
  .

eq
  < O : C | Att: S, Pr: ((L, (A |-> D)), bury(A , NeAL) ; SL), PrQ: W,
    Lcnt: N > =
  < O : C | Att: S, Pr: (L, bury(NeAL) ; SL), PrQ: W, Lcnt: N >
  .

endm

ifdef(`MODELCHECK',dnl
*** The predicates we can define on configurations.
mod CREOL-PREDICATES is
  protecting CREOL-MODEL-CHECKER .
  ops objcnt maxobjcnt minobjcnt : Cid Nat -> Prop .
  op hasvalue : Oid Vid Data -> Prop .
  var A : Vid .
  var D : Data .
  var C : Cid .
  var O : Oid .
  vars S S' L L' : Subst .
  var P : Process .
  var Q : MProc .
  vars N N' : Nat .
  var c : Configuration .

  eq { c < C : Cl | Inh: I:InhList`,' Par: AL:VidList`,' Att: S`,' Mtds: M:MMtd`,' Ocnt: N > } |= objcnt(C`,' N') = N == N' .
  eq { c < C : Cl | Inh: I:InhList`,' Par: AL:VidList`,' Att: S`,' Mtds: M:MMtd`,' Ocnt: N > } |= maxobjcnt(C`,' N') = N <= N' .
  eq { c < C : Cl | Inh: I:InhList`,' Par: AL:VidList`,' Att: S`,' Mtds: M:MMtd`,' Ocnt: N > } |= minobjcnt(C`,' N') = N >= N' .
  eq { c < O : C | Att: S`,' Pr: P`,' PrQ: Q`,' Lcnt: N > } |= hasvalue(O`,' A`,' D) = D == S[A] .

endm
)dnl

eof
