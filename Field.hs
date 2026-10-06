{-# LANGUAGE DataKinds, KindSignatures, ScopedTypeVariables #-}
import GHC.TypeLits (Nat, KnownNat, natVal)
import Data.Proxy (Proxy (..))

-- 法 p を「型」に持つ、有限体 F_p の要素
newtype Fp (p :: Nat) = Fp Integer deriving Eq
instance KnownNat p => Show (Fp p) where
  show (Fp x) = show x ++ " (mod " ++ show (natVal (Proxy :: Proxy p)) ++ ")"

modulus :: forall p. KnownNat p => Fp p -> Integer
modulus _ = natVal (Proxy :: Proxy p)

mk :: forall p. KnownNat p => Integer -> Fp p
mk x = Fp (x `mod` natVal (Proxy :: Proxy p))

instance KnownNat p => Num (Fp p) where
  Fp a + Fp b = mk (a + b)
  Fp a * Fp b = mk (a * b)
  negate (Fp a) = mk (negate a)
  fromInteger = mk
  abs = id
  signum _ = 1

-- 体の演算だけを使って書いた、1つのアルゴリズム（ホーナー法による多項式の値）
horner :: Num a => [a] -> a -> a
horner cs x = foldr (\c acc -> c + x * acc) 0 cs

power :: Num a => a -> Integer -> a
power _ 0 = 1
power a n | even n    = let h = power a (n `div` 2) in h * h
          | otherwise = a * power a (n - 1)

main :: IO ()
main = do
  let cs = [3, 0, 2, 5]                       -- 3 + 2x^2 + 5x^3
  print (horner cs (4 :: Integer))            -- 整数として
  print (horner (map fromInteger cs) (4 :: Fp 7))
  print (horner (map fromInteger cs) (4 :: Fp 101))
  -- フェルマーの小定理：a^(p-1) = 1（a ≠ 0）
  print (power (3 :: Fp 101) 100)
  print (power (5 :: Fp 2147483647) 2147483646)
