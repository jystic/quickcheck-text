{-# LANGUAGE TemplateHaskell #-}

module Main where

import           Control.Monad

import           Data.Bits
import qualified Data.ByteString      as BS
import qualified Data.Text as T
import           Data.Text.Encoding

import           System.Exit

import           Test.QuickCheck
import           Test.QuickCheck.Utf8

prop_decodes_without_exception :: Property
prop_decodes_without_exception = forAll utf8BS $ \bs ->
  let t = decodeUtf8 bs in
  (T.length t >=) 0 === True

prop_oneByte_lsb :: Property
prop_oneByte_lsb = forAll oneByte $ \bs ->
  let b = head $ BS.unpack bs
  in testBit b 7 === False

prop_oneByte_range :: Property
prop_oneByte_range = forAll oneByte $ \bs ->
  let s = sum $ fmap fromIntegral $ BS.unpack bs
  in (s >= 0 && s <= 127)

prop_twoByte_range :: Property
prop_twoByte_range = forAll twoByte $ \bs ->
  let s = sum $ fmap fromIntegral $ BS.unpack bs
  in (s >= 320 && s <= 65439)

prop_threeByte_range :: Property
prop_threeByte_range = forAll threeByte $ \bs ->
  let s = sum $ fmap fromIntegral $ BS.unpack bs
  in (s >= 480 && s <= 16777071)

prop_validUtf81_length :: Property
prop_validUtf81_length = forAll utf8BS1 $ \bs ->
  BS.length bs >= 1

prop_validUtf81_valid :: Property
prop_validUtf81_valid = forAll utf8BS1 $ \bs ->
  let t = decodeUtf8 bs in
  (T.length t >= 1) === True

return []
props :: IO Bool
props = $quickCheckAll

main :: IO ()
main = props >>= flip when exitFailure . not
