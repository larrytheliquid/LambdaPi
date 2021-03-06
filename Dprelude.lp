-- identity and const
let id    = (\ a x -> x) :: forall (a :: *) . a -> a 
let const = (\ a b x y -> x) :: forall (a :: *) (b :: *) . a -> b -> a
let comp = (\A B C f g x -> f (g x)) :: forall (A :: *) (B :: *) (C :: *) . (B -> C) -> (A -> B) -> A -> C

-- type of natural numbers
data Nat :: * where
   Zero :: Nat ,
   Succ :: Nat -> Nat

let natElim = NatElim

-- addition of natural numbers
let plus =
  NatElim
    ( \ _ -> Nat -> Nat )           -- motive
    ( \ n -> n )                    -- case for Zero
    ( \ p rec n -> Succ (rec n) )   -- case for Succ

-- predecessor, mapping 0 to 0
let pred =
  NatElim
    ( \ _ -> Nat )
    Zero
    ( \ n' _rec -> n' )

-- a simpler elimination scheme for natural numbers
let natFold =
  ( \ m mz ms -> NatElim
                   ( \ _ -> m )
                   mz
                   ( \ n' rec -> ms rec ) )
  :: forall (m :: *) . m -> (m -> m) -> Nat -> m

-- an eliminator for natural numbers that has special
-- cases for 0 and 1
let nat1Elim =
  ( \ m m0 m1 ms -> NatElim m m0
                            (\ p rec -> NatElim (\ n -> m (Succ n)) m1 ms p) )
  :: forall (m :: Nat -> *) . m 0 -> m 1 ->
     (forall n :: Nat . m (Succ n) -> m (Succ (Succ n))) ->
     forall (n :: Nat) . m n

-- an eliminator for natural numbers that has special
-- cases for 0, 1 and 2
let nat2Elim =
  ( \ m m0 m1 m2 ms -> nat1Elim m m0 m1
                                (\ p rec -> NatElim (\ n -> m (Succ (Succ n))) m2 ms p) )
  :: forall (m :: Nat -> *) . m 0 -> m 1 -> m 2 ->
     (forall n :: Nat . m (Succ (Succ n)) -> m (Succ (Succ (Succ n)))) ->
     forall (n :: Nat) . m n
-- increment by one
let inc = natFold Nat (Succ Zero) Succ

-------     
-- fin type
data Fin :: Nat -> * where 
  FZero :: forall (n :: Nat) . Fin (Succ n),
  FSucc :: forall (n :: Nat) . Fin n -> Fin (Succ n)

let finElim = FinElim

-- embed Fin into Nat
let finNat = FinElim (\ _ _ -> Nat)
                     (\ _ -> Zero)
                     (\ _ _ rec -> Succ rec)

-- unit type
let Unit = Fin 1
-- constructor
let U = FZero 0
-- eliminator
let unitElim =
  ( \ m mu -> FinElim ( nat1Elim (\ n -> Fin n -> *)
                                 (\ _ -> Unit)
                                 (\ x -> m x)
                                 (\ _ _ _ -> Unit) )
                      ( NatElim  (\ n -> NatElim (\ n -> Fin (Succ n) -> *)
                                                (\ x -> m x)
                                                (\ _ _ _ -> Unit)
                                                n (FZero n))
                                mu
                                (\ _ _ -> U) )
                      ( \ n f _ -> FinElim (\ n f -> NatElim (\ n -> Fin (Succ n) -> *)
                                                             (\ x -> m x)
                                                             (\ _ _ _ -> Unit)
                                                             n (FSucc n f))
                                           (\ _ -> U)
                                           (\ _ _ _ -> U)
                                           n f )
                      1 )
  :: forall (m :: Unit -> *) . m U -> forall (u :: Unit) . m u

-- empty type
let Void = Fin 0
-- eliminator
let voidElim =
  ( \ m -> FinElim (NatElim (\ n -> Fin n -> *)
                            (\ x -> m x)
                            (\ _ _ _ -> Unit))
                   (\ _ -> U)
                   (\ _ _ _ -> U)
                   0 )
  :: forall (m :: Void -> *) (v :: Void) . m v

-- type of booleans 
let Bool = Fin 2 
-- constructors
let False = FZero 1
let True  = FSucc 1 (FZero 0)
------- eliminator
let boolElim =
  ( \ m mf mt -> FinElim ( nat2Elim (\ n -> Fin n -> *)
                                    (\ _ -> Unit) (\ _ -> Unit)
                                    (\ x -> m x)
                                    (\ _ _ _ -> Unit) )
                         ( nat1Elim ( \ n -> nat1Elim (\ n -> Fin (Succ n) -> *)
                                                      (\ _ -> Unit)
                                                      (\ x -> m x)
                                                      (\ _ _ _ -> Unit)
                                                      n (FZero n))
                                    U mf (\ _ _ -> U) )
                         ( \ n f _ -> FinElim ( \ n f -> nat1Elim (\ n -> Fin (Succ n) -> *)
                                                                  (\ _ -> Unit)
                                                                  (\ x -> m x)
                                                                  (\ _ _ _ -> Unit)
                                                                  n (FSucc n f) )
                                              ( NatElim
                                                  ( \ n -> NatElim
                                                             (\ n -> Fin (Succ (Succ n)) -> *)
                                                             (\ x -> m x)
                                                             (\ _ _ _ -> Unit)
                                                             n (FSucc (Succ n) (FZero n)) )
                                                  mt (\ _ _ -> U) )
                                              ( \ n f _ -> FinElim
                                                             (\ n f -> NatElim
                                                                         (\ n -> Fin (Succ (Succ n)) -> *)
                                                                         (\ x -> m x)
                                                                         (\ _ _ _ -> Unit)
                                                                         n (FSucc (Succ n) (FSucc n f)))
                                                             (\ _ -> U)
                                                             (\ _ _ _ -> U)
                                                             n f )
                                              n f )
                         2 )
  :: forall (m :: Bool -> *) . m False -> m True -> forall (b :: Bool) . m b

-- boolean not, and, or, equivalence, xor
let not = boolElim (\ _ -> Bool) True False
let and = boolElim (\ _ -> Bool -> Bool) (\ _ -> False) (id Bool)
let or  = boolElim (\ _ -> Bool -> Bool) (id Bool) (\ _ -> True)
let iff = boolElim (\ _ -> Bool -> Bool) not (id Bool)
let xor = boolElim (\ _ -> Bool -> Bool) (id Bool) not

-- even, odd, isZero, isSucc
let even    = natFold Bool True not
let odd     = natFold Bool False not
let isZero  = natFold Bool True (\ _ -> False)
let isSucc  = natFold Bool False (\ _ -> True)

-- equality on natural numbers
let natEq =
  NatElim
    ( \ _ -> Nat -> Bool )
    ( NatElim
        ( \ _ -> Bool )
        True
        ( \ n' _ -> False ) )
    ( \ m' rec_m' -> NatElim
                       ( \ _ -> Bool )
                       False
                       ( \ n' _ -> rec_m' n' ))

-- "oh so true"
let Prop = boolElim (\ _ -> *) Void Unit

-- reflexivity of equality on natural numbers
let pNatEqRefl =
  NatElim
    (\ n -> Prop (natEq n n))
    U
    (\ n' rec -> rec)
  :: forall (n :: Nat) . Prop (natEq n n)

-- alias for type-level negation 
let Not = (\ a -> a -> Void) :: * -> *

--equality type
data Eq :: forall (A :: *) (x :: A) (y :: A) . * where
  Refl :: forall (A :: *) (x :: A) . Eq A x x

-- a more natural eliminator
let eqElim = (\A P mRefl ->
                EqElim (\A -> P) (\A -> mRefl) A)
             :: forall (A :: *)
                       (P :: forall (x :: A) (y :: A) (a :: Eq A x y) . *)
                       (mRefl :: forall x :: A . P x x (Refl A x))
                       (x :: A)
                       (y :: A)
                       (a :: Eq A x y) .
                P x y a 



-- Leibniz prinicple (look at the type signature)
let leibniz =
  ( \ a b f -> eqElim a
                 (\ x y eq_x_y -> Eq b (f x) (f y))
                 (\ x -> Refl b (f x)) )
  :: forall (a :: *) (b :: *) (f :: a -> b) (x :: a) (y :: a) .
     Eq a x y -> Eq b (f x) (f y)

-- symmetry of (general) equality
let symm =
  ( \ a -> eqElim a
             (\ x y eq_x_y -> Eq a y x)
             (\ x -> Refl a x) )
  :: forall (a :: *) (x :: a) (y :: a) .
     Eq a x y -> Eq a y x

-- transitivity of (general) equality
let tran =
  ( \ a x y z eq_x_y -> eqElim a
                          (\ x y eq_x_y -> forall (z :: a) . Eq a y z -> Eq a x z)
                          (\ x z eq_x_z -> eq_x_z)
                          x y eq_x_y z )
  :: forall (a :: *) (x :: a) (y :: a) (z :: a) .
     Eq a x y -> Eq a y z -> Eq a x z

-- apply an equality proof on two types
let apply =
  eqElim * (\ a b _ -> a -> b) (\ _ x -> x)
  :: forall (a :: *) (b :: *) (p :: Eq * a b) . a -> b

-- proof that 1 is not 0
let p1IsNot0 =
  (\ p -> apply Unit Void
                (leibniz Nat *
                         (natElim (\ _ -> *) Void (\ _ _ -> Unit))
                         1 0 p)
                U)
  :: Not (Eq Nat 1 0)

-- proof that 0 is not 1
let p0IsNot1 =
  (\ p -> p1IsNot0 (symm Nat 0 1 p))
  :: Not (Eq Nat 0 1)

-- proof that zero is not a successor
let p0IsNoSucc = 
  natElim
    ( \ n -> Not (Eq Nat 0 (Succ n)) )
    p0IsNot1
    ( \ n' rec_n' eq_0_SSn' ->
      rec_n' (leibniz Nat Nat pred Zero (Succ (Succ n')) eq_0_SSn') )


-- lists and vectors
data List :: * ->  * where 
  LNil  :: forall (A :: *) . List A,
  LCons :: forall (A :: *) . A -> List A -> List A

data Vec :: * -> Nat -> * where
  Nil  :: forall (A :: *) . Vec A 0,
  Cons :: forall (A :: *) (n :: Nat) . A -> Vec A n -> Vec A (Succ n)


-- generate a vector of given length from a specified element (replicate)
let replicate =
  ( NatElim
      ( \ n -> forall (a :: *) . a -> Vec a n )
      ( \ a _ -> Nil a )
      ( \ n' rec_n' a x -> Cons a n' x (rec_n' a x) ) )
  :: forall (n :: Nat) . forall (a :: *) . a -> Vec a n

-- alternative definition of replicate
let replicate' =
  (\ a n x -> NatElim (Vec a)
                      (Nil a)
                      (\ n' rec_n' -> Cons a n' x rec_n') n)
  :: forall (a :: *) (n :: Nat) . a -> Vec a n

-- generate a vector of given length n, containing the natural numbers smaller than n
let fromto =
  NatElim
    ( \ n -> Vec Nat n )
    ( Nil Nat )
    ( \ n' rec_n' -> Cons Nat n' n' rec_n' )

--more natural eliminator
let vecElim =
  ( \ A P mn mc n x ->  VecElim (\A -> P) (\A -> mn) (\A -> mc)  A n x )
   :: forall (A  :: *)
             (P  :: forall (n :: Nat) . Vec A n -> *)
             (mn :: P 0 (Nil A))
             (mc :: forall (n :: Nat) (b :: A) (v :: Vec A n) . P n v -> P (Succ n) (Cons A n b v))
             (n  :: Nat)
             (v  :: Vec A n) .
             P n v

-- append two vectors
let append =
  ( \ a -> vecElim a
             (\ m _ -> forall (n :: Nat) . Vec a n -> Vec a (plus m n))
             (\ _ v -> v)
             (\ m v vs rec n w -> Cons a (plus m n) v (rec n w)))
  ::  forall (a :: *) (m :: Nat) (v :: Vec a m) (n :: Nat) (w :: Vec a n).
      Vec a (plus m n)

-- helper function for tail, see below
let tail' =
  (\ a -> vecElim a ( \ m v -> forall (n :: Nat) . Eq Nat m (Succ n) -> Vec a n )
                    ( \ n eq_0_SuccN -> voidElim ( \ _ -> Vec a n )
                                                 ( p0IsNoSucc n eq_0_SuccN ) )
                    ( \ m' v vs rec_m' n eq_SuccM'_SuccN ->
                      eqElim Nat
                             (\ m' n e -> Vec a m' -> Vec a n)
                             (\ _ v -> v)
                             m' n
                             (leibniz Nat Nat pred (Succ m') (Succ n) eq_SuccM'_SuccN) vs))
  :: forall (a :: *) (m :: Nat) . Vec a m -> forall (n :: Nat) . Eq Nat m (Succ n) -> Vec a n

-- compute the tail of a vector
let tail =
  (\ a n v -> tail' a (Succ n) v n (Refl Nat (Succ n)))
  :: forall (a :: *) (n :: Nat) . Vec a (Succ n) -> Vec a n

-- projection out of a vector
let at =
  (\ a -> vecElim a ( \ n v -> Fin n -> a )
                    ( \ f -> voidElim (\ _ -> a) f )
                    ( \ n' v vs rec_n' f_SuccN' ->
                      finElim ( \ n _ -> Eq Nat n (Succ n') -> a )
                              ( \ n e -> v )
                              ( \ n f_N _ eq_SuccN_SuccN' ->
                                rec_n' (eqElim Nat
                                               (\ x y e -> Fin x -> Fin y)
                                               (\ _ f -> f)
                                               n n'
                                               (leibniz Nat Nat pred
                                                        (Succ n) (Succ n') eq_SuccN_SuccN')
                                               f_N))
                              (Succ n')
                              f_SuccN'
                              (Refl Nat (Succ n'))))
  :: forall (a :: *) (n :: Nat) . Vec a n -> Fin n -> a

-- head of a vector
let head =
  (\ a n v -> at a (Succ n) v (FZero n))
  :: forall (a :: *) (n :: Nat) . Vec a (Succ n) -> a

--vector map
 let map =
   (\ a b f -> vecElim a ( \ n _ -> Vec b n )
                         ( Nil b )
                         ( \ n x _ rec -> Cons b n (f x) rec ))
   :: forall (a :: *) (b :: *) (f :: a -> b) (n :: Nat) . Vec a n -> Vec b n
 
-- proofs that 0 is the neutral element of addition
-- one direction is trivial by definition of plus:
let p0PlusNisN =
  Refl Nat
  :: forall n :: Nat . Eq Nat (plus 0 n) n

-- the other direction requires induction on N:
let pNPlus0isN =
  natElim ( \ n -> Eq Nat (plus n 0) n )
          ( Refl Nat 0 )
          ( \ n' rec -> leibniz Nat Nat Succ (plus n' 0) n' rec )
  :: forall n :: Nat . Eq Nat (plus n 0) n


