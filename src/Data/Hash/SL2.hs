-- |
-- Module     : Data.Hash.SL2
-- License    : MIT
-- Maintainer : Sam Rijs <srijs@airpost.net>
--
-- An algebraic hash function, inspired by the paper "Hashing with SL2" by
-- Tillich and Zemor.
--
-- The hash function is based on matrix multiplication in the special linear group
-- of degree 2, over a Galois field of order 2^127,  with all computations modulo
-- the polynomial x^127 + x^63 + 1.
--
-- This construction gives some nice properties, which traditional "bit-scambling"
-- hash functions don't possess, including it being composable. It holds:
--
-- prop> hash (m1 <> m2) == hash m1 <> hash m2
--
-- All operations in this package are implemented in a very efficient manner using SSE instructions.
--

module Data.Hash.SL2 (Hash, hash, (<+), (+>), (<|), (|>), parse) where

import Data.Hash.SL2.Internal
import Data.Hash.SL2.Unsafe
import qualified Data.Hash.SL2.Mutable as Mutable

import System.IO.Unsafe

import Data.ByteString (ByteString)

import Data.Monoid
import Data.Functor
import Data.Foldable (Foldable)

instance Show Hash where
  show h = unsafePerformIO $ unsafeUseAsPtr h Mutable.serialize

instance Eq Hash where
  a == b = unsafePerformIO $ unsafeUseAsPtr2 a b Mutable.eq

instance Monoid Hash where
  mempty = fst $ unsafePerformIO $ Mutable.withNew Mutable.unit
  mappend a b = fst $ unsafePerformIO $ Mutable.withNew (unsafeUseAsPtr2 a b . Mutable.concat)

-- | /O(n)/ Calculate the hash of the 'ByteString'. Alias for @('mempty' '<+')@.
hash :: ByteString -> Hash
hash = (<+) mempty

-- | /O(n)/ Append the hash of the 'ByteString' to the existing 'Hash'.
-- A significantly faster equivalent of @((. 'hash') . ('<>'))@.
infixl 7 <+
(<+) :: Hash -> ByteString -> Hash
(<+) h s = fst $ unsafePerformIO $ Mutable.withCopy h $ Mutable.append s

-- | /O(n)/ Prepend the hash of the 'ByteString' to the existing 'Hash'.
-- A significantly faster equivalent of @(('<>') . 'hash')@.
infixr 7 +>
(+>) :: ByteString -> Hash -> Hash
(+>) s h = fst $ unsafePerformIO $ Mutable.withCopy h $ Mutable.prepend s

-- | /O(n)/ Append the hash of every 'ByteString' to the existing 'Hash', from left to right.
-- A significantly faster equivalent of @('foldl' ('<+'))@.
infixl 7 <|
(<|) :: Foldable t => Hash -> t ByteString -> Hash
(<|) h ss = fst $ unsafePerformIO $ Mutable.withCopy h $ Mutable.foldAppend ss

-- | /O(n)/ Prepend the hash of every 'ByteString' to the existing 'Hash', from right to left.
-- A significantly faster equivalent of @('flip' ('foldr' ('+>')))@.
infixr 7 |>
(|>) :: Foldable t => t ByteString -> Hash -> Hash
(|>) ss h = fst $ unsafePerformIO $ Mutable.withCopy h $ Mutable.foldPrepend ss

-- | /O(1)/ Parse the representation generated by 'show'.
parse :: String -> Maybe Hash
parse s = (\(h, r) -> h <$ r) $ unsafePerformIO $ Mutable.withNew $ Mutable.unserialize s
