module LambdaPi.Printer where
  import Interpreter.Types
  import LambdaPi.Types
 
  import Prelude hiding (print)
  import Text.PrettyPrint.HughesPJ hiding (parens)
  import qualified Text.PrettyPrint.HughesPJ as PP




--LAMBDAPI


{- LINE 5 "Printer-LP.lhs" #-}
  iPrint_ :: Int -> Int -> ITerm_ -> Doc
  iPrint_ p ii (Ann_ c ty)       =  parensIf (p > 1) (cPrint_ 2 ii c <> text " :: " <> cPrint_ 0 ii ty)
  iPrint_ p ii Star_             =  text "*"
  iPrint_ p ii (Pi_ vn d (Inf_ (Pi_ vn' d' r)))
                                 =  parensIf (p > 0) (nestedForall_ (ii + 2) [(ii + 1, vn', d'), (ii, vn, d)] r)
  iPrint_ p ii (Pi_ vn d r)         =  parensIf (p > 0) (sep [text "forall " <> text vn{--(vars !! ii)--} <> text " :: " <> cPrint_ 0 ii d <> text " .", cPrint_ 0 (ii + 1) r])
  iPrint_ p ii (Bound_ k vn)     =  text ('^':vn) --(vars !! (ii - k - 1))
  iPrint_ p ii (Free_ (Global s))=  text s
  iPrint_ p ii (Free_ (Local _ s))=  text ('$':s)
  iPrint_ p ii (i :$: c)         =  parensIf (p > 2) (sep [iPrint_ 2 ii i, nest 2 (cPrint_ 3 ii c)])
  iPrint_ p ii Nat_              =  text "Nat"
  iPrint_ p ii (NatElim_ m z s n)=  iPrint_ p ii (Free_ (Global "natElim") :$: m :$: z :$: s :$: n)
  iPrint_ p ii (Vec_ a n)        =  iPrint_ p ii (Free_ (Global "Vec") :$: a :$: n)
  iPrint_ p ii (VecElim_ a m mn mc n xs)
                                 =  iPrint_ p ii (Free_ (Global "vecElim") :$: a :$: m :$: mn :$: mc :$: n :$: xs)
  iPrint_ p ii (Eq_ a x y)       =  iPrint_ p ii (Free_ (Global "Eq") :$: a :$: x :$: y)
  iPrint_ p ii (EqElim_ a m mr x y eq)
                                 =  iPrint_ p ii (Free_ (Global "eqElim") :$: a :$: m :$: mr :$: x :$: y :$: eq)
  iPrint_ p ii (Fin_ n)          =  iPrint_ p ii (Free_ (Global "Fin") :$: n)
  iPrint_ p ii (FinElim_ m mz ms n f)
                                 =  iPrint_ p ii (Free_ (Global "finElim") :$: m :$: mz :$: ms :$: n :$: f)
  iPrint_ p ii x                 =  text ("[" ++ show x ++ "]")
{- LINE 28 "Printer-LP.lhs" #-}

  cPrint_ :: Int -> Int -> CTerm_ -> Doc
  cPrint_ p ii (Inf_ i)    = iPrint_ p ii i
  cPrint_ p ii (Lam_ vn c) = parensIf (p > 0) (text "\\ " <> text vn {--CHANGED(vars !! ii)--} <> text " -> " <> cPrint_ 0 (ii + 1) c)
  cPrint_ p ii Zero_       = fromNat_ 0 ii Zero_     --  text "Zero"
  cPrint_ p ii (Succ_ n)   = fromNat_ 0 ii (Succ_ n) --  iPrint_ p ii (Free_ (Global "Succ") :$: n)
  cPrint_ p ii (Nil_ a)    = iPrint_ p ii (Free_ (Global "Nil") :$: a)
  cPrint_ p ii (Cons_ a n x xs) =
                             iPrint_ p ii (Free_ (Global "Cons") :$: a :$: n :$: x :$: xs)
  cPrint_ p ii (Refl_ a x) = iPrint_ p ii (Free_ (Global "Refl") :$: a :$: x)
  cPrint_ p ii (FZero_ n)  = iPrint_ p ii (Free_ (Global "FZero") :$: n)
  cPrint_ p ii (FSucc_ n f)= iPrint_ p ii (Free_ (Global "FSucc") :$: n :$: f)
{- LINE 40 "Printer-LP.lhs" #-}
  parensIf :: Bool -> Doc -> Doc
  parensIf True  = PP.parens
  parensIf False = id

  fromNat_ :: Int -> Int -> CTerm_ -> Doc
  fromNat_ n ii Zero_ = int n
  fromNat_ n ii (Succ_ k) = fromNat_ (n + 1) ii k
  fromNat_ n ii t = parensIf True (int n <> text " + " <> cPrint_ 0 ii t)
{- LINE 45 "Printer-LP.lhs" #-}
  nestedForall_ :: Int -> [(Int, String, CTerm_)] -> CTerm_ -> Doc
  nestedForall_ ii ds (Inf_ (Pi_ vn d r)) = nestedForall_ (ii + 1)  ((ii, vn, d) : ds) r
  nestedForall_ ii ds x                = sep [text "forall " <> sep [parensIf True (text vn {--(vars !! n)--} <> text " :: " <> cPrint_ 0 n d) | (n,vn,d) <- reverse ds] <> text " .", cPrint_ 0 ii x]

