module Test.QuickCheck.Utf8(
    genValidUtf8
  , utf8BS
  , genValidUtf81
  , utf8BS1
    -- * Generators for single characters
  , oneByte
  , twoByte
  , threeByte
) where

import           Control.Monad

import           Data.Binary.Builder

import           Data.ByteString     (ByteString)
import qualified Data.ByteString     as BS
import qualified Data.ByteString.Lazy     as BL
import           Data.Text           (Text)
import           Data.Text.Encoding
import           Data.Text.Internal.Encoding.Utf8
import           Data.Word

import           Test.QuickCheck

-- |
-- Generate a possibly-empty valid UTF-8 'Text' value.
genValidUtf8 :: Gen Text
genValidUtf8 = fmap decodeUtf8 utf8BS

-- |
-- Generate a possibly-empty sequence of bytes which represent a valid
-- UTF-8 code point.
utf8BS :: Gen ByteString
utf8BS = fmap BS.concat $ elements symbolTypes  >>= listOf

-- |
-- Like 'genValidUtf8', but does not allow empty 'Text' values.
genValidUtf81 :: Gen Text
genValidUtf81 = fmap decodeUtf8 utf8BS1

-- |
-- Like 'utf8BS', but does not allow empty 'ByteString's.
utf8BS1 :: Gen ByteString
utf8BS1 = fmap BS.concat $ elements symbolTypes  >>= listOf1

symbolTypes :: [Gen ByteString]
symbolTypes = [ oneByte
              , twoByte
              , threeByte
              ]

inRange :: Int -> Int -> Gen Word8
inRange lo hi = fmap fromIntegral $ elements [lo..hi]

-- | Single-byte UTF-8 (i.e., a standard ASCII byte with a cleared MSB).
oneByte :: Gen ByteString
oneByte = fmap (BS.pack . return) $
  inRange 0 127 -- 0bbbbbbb

twoByte :: Gen ByteString
twoByte = do
  b1 <- inRange 0xC2 0xDF -- 110bbbbb
  b2 <- nonInitial
  return . buildUtf $ putBytes2 b1 b2

threeByte :: Gen ByteString
threeByte = do
  (b1, b2) <- oneof [b3_1, b3_2, b3_3, b3_4]
  b3 <- nonInitial
  return . buildUtf $ putBytes3 b1 b2 b3
 where
  b3_1 = (,) `fmap` return 0xE0 `ap` inRange 0xA0 0xBF

  b3_2 = (,) `fmap` inRange 0xE1 0xEC `ap` nonInitial

  b3_3 = (,) `fmap` return 0xED `ap` inRange 0x80 0x9F

  b3_4 = (,) `fmap` inRange 0xEE 0xEF `ap` nonInitial

buildUtf :: Builder -> ByteString 
buildUtf = BS.concat . BL.toChunks . toLazyByteString

putBytes2 :: Word8 -> Word8 -> Builder
putBytes2 b1 b2 =  putCharUtf8 $ chr2 b1 b2

putBytes3 :: Word8 -> Word8 -> Word8 -> Builder
putBytes3 b1 b2 b3 =  putCharUtf8 $ chr3 b1 b2 b3

nonInitial :: Gen Word8
nonInitial = inRange 0x80 0xBF
