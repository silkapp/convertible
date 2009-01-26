{-
Copyright (C) 2009 John Goerzen <jgoerzen@complete.org>

All rights reserved.

For license and copyright information, see the file COPYRIGHT
-}

module TestTime where
import TestInfrastructure
import Data.Convertible
import Test.QuickCheck
import Test.QuickCheck.Tools
import Test.QuickCheck.Instances
import qualified System.Time as ST
import Data.Time
import Data.Time.Clock.POSIX
import Data.Ratio

instance Arbitrary ST.ClockTime where
    arbitrary = do r1 <- arbitrary
                   r2 <- sized $ \n -> choose (0, 1000000000000 - 1)
                   return (ST.TOD r1 r2)
    coarbitrary (ST.TOD a b) = coarbitrary a . coarbitrary b

instance Arbitrary NominalDiffTime where
    arbitrary = do r <- arbitrary
                   return $ convert (r::ST.ClockTime)

propCltCalt :: ST.ClockTime -> Result
propCltCalt x =
    safeConvert x @?= Right (ST.toUTCTime x)

propCltCaltClt :: ST.ClockTime -> Result
propCltCaltClt x =
    Right x @=? do r1 <- ((safeConvert x)::ConvertResult ST.CalendarTime)
                   safeConvert r1

propCltPT :: ST.ClockTime -> Result
propCltPT x@(ST.TOD y z) =
    safeConvert x @?= Right (r::POSIXTime)
    where r = fromRational $ fromInteger y `plusorminus` fromRational (z % 1000000000000)
          plusorminus = if y < 0 then (-) else (+)

propPTClt :: POSIXTime -> Result
propPTClt x =
    safeConvert x @?= Right (r::ST.ClockTime)
    where r = ST.TOD rsecs rpico
          rsecs = (truncate x :: Integer)
          rpico = truncate $ abs $ 1000000000000 * (x - (fromIntegral rsecs))

propCltPTClt :: ST.ClockTime -> Result
propCltPTClt x =
    Right (toTOD x) @=? case do r1 <- (safeConvert x)::ConvertResult POSIXTime
                                safeConvert r1
                        of Left x -> Left x
                           Right y -> Right $ toTOD y
    where toTOD (ST.TOD x y) = (x, y)
{-
    Right x @=? do r1 <- (safeConvert x)::ConvertResult POSIXTime
                   safeConvert r1
-}

propPTCltPT :: POSIXTime -> Result
propPTCltPT x =
    Right x @=? do r1 <- (safeConvert x)::ConvertResult ST.ClockTime
                   safeConvert r1

allt = [q "ClockTime -> CalendarTime" propCltCalt,
        q "ClockTime -> CalendarTime -> ClockTime" propCltCaltClt,
        q "ClockTime -> POSIXTime" propCltPT,
        q "POSIXTime -> ClockTime" propPTClt,
        q "identity ClockTime -> POSIXTime -> ClockTime" propCltPTClt,
        q "identity POSIXTime -> ClockTime -> POSIXTime" propPTCltPT]