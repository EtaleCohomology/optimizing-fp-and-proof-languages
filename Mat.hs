{-# LANGUAGE DataKinds, KindSignatures, ScopedTypeVariables #-}
import GHC.TypeLits (Nat, KnownNat, natVal)
import Data.Proxy (Proxy (..))
import Data.List (transpose)

-- 行数 m と列数 n を「型」に持つ行列
newtype Mat (m :: Nat) (n :: Nat) = Mat [[Double]] deriving Show

fromLists :: forall m n. (KnownNat m, KnownNat n) => [[Double]] -> Maybe (Mat m n)
fromLists rows
  | length rows == fromIntegral (natVal (Proxy :: Proxy m))
  , all ((== fromIntegral (natVal (Proxy :: Proxy n))) . length) rows = Just (Mat rows)
  | otherwise = Nothing

-- (m × n) と (n × k) の積は (m × k)。内側の次元 n が一致しなければ、型が合わない
mmul :: Mat m n -> Mat n k -> Mat m k
mmul (Mat a) (Mat b) = Mat [ [ sum (zipWith (*) r c) | c <- transpose b ] | r <- a ]

main :: IO ()
main = do
  let Just w = fromLists [[1, 2, 3], [4, 5, 6]] :: Maybe (Mat 2 3)   -- 重み行列 2×3
      Just x = fromLists [[1], [0], [2]]          :: Maybe (Mat 3 1)   -- 入力 3×1
  print (mmul w x)                                                    -- 結果は 2×1
