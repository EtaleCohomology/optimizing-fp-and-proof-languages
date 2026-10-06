{-# LANGUAGE DataKinds, KindSignatures #-}
import GHC.TypeLits (Nat)
newtype Mat (m :: Nat) (n :: Nat) = Mat [[Double]]
mmul :: Mat m n -> Mat n k -> Mat m k
mmul (Mat a) (Mat b) = Mat a
w = Mat [[1,2,3],[4,5,6]] :: Mat 2 3
x = Mat [[1],[0]]         :: Mat 2 1
bad = mmul w x
main = return ()
