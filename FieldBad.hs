{-# LANGUAGE DataKinds, KindSignatures #-}
import GHC.TypeLits (Nat)
newtype Fp (p :: Nat) = Fp Integer
add :: Fp p -> Fp p -> Fp p
add (Fp a) (Fp b) = Fp (a + b)
bad = add (Fp 3 :: Fp 7) (Fp 5 :: Fp 101)
main = return ()
