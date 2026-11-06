classdef TestQuantities < LdemTestCase
    %TESTQUANTITIES  Unit tests of the units of the case files (ldem.schema).

    methods (Test, TestTags = {'Unit'})
        function convertsEveryDimension(testCase)
            parse = @ldem.schema.parseQuantity;
            testCase.verifyEqual(parse("3.87 GPa", "pressure"), 3.87e9);
            testCase.verifyEqual(parse("32 GPa", "pressure"), 32e9);
            testCase.verifyEqual(parse("1 mm", "length"), 1e-3);
            testCase.verifyEqual(parse("28 mm", "length"), 0.028);
            testCase.verifyEqual(parse("0.5 km", "length"), 500);
            testCase.verifyEqual(parse("0.35 us", "time"), 3.5e-7);
            testCase.verifyEqual(parse("2.8 ms", "time"), 2.8e-3);
            testCase.verifyEqual(parse("1500 kg/m3", "density"), 1500);
            testCase.verifyEqual(parse("2 g/cm3", "density"), 2000);
            testCase.verifyEqual(parse("25 1/ms", "rate"), 25000);
            testCase.verifyEqual(parse("0.5 kN/m", "toughness"), 500);
            testCase.verifyEqual(parse("4 mm/s", "velocity"), 4e-3);
            testCase.verifyEqual(parse("2 kN/s", "forcerate"), 2000);
            testCase.verifyEqual(parse("24.5 modules", "modules"), 24.5);
        end

        function numbersWithoutUnitAreSi(testCase)
            testCase.verifyEqual(ldem.schema.parseQuantity(0.003, "length"), 0.003);
            testCase.verifyEqual(ldem.schema.parseQuantity("3.87e9", "pressure"), 3.87e9);
            testCase.verifyEqual(ldem.schema.parseQuantity("  7  ", "number"), 7);
        end

        function exponentInTheMantissaIsAccepted(testCase)
            testCase.verifyEqual(ldem.schema.parseQuantity("3.5E-1 us", "time"), 3.5e-1 * 1e-6, 'RelTol', 1e-15);
        end

        function wrongUnitsAndTextAreRejected(testCase)
            testCase.verifyError(@() ldem.schema.parseQuantity("3 kg", "length"), 'ldem:case:badUnit');
            testCase.verifyError(@() ldem.schema.parseQuantity("fast", "time"), 'ldem:case:badQuantity');
            testCase.verifyError(@() ldem.schema.parseQuantity("3 mm", "number"), 'ldem:case:badUnit');
            testCase.verifyError(@() ldem.schema.parseQuantity(Inf, "time"), 'ldem:case:badQuantity');
            testCase.verifyError(@() ldem.schema.parseQuantity([1 2], "time"), 'ldem:case:badQuantity');
            testCase.verifyError(@() ldem.schema.parseQuantity("1", "colour"), 'ldem:schema:unknownDimension');
        end

        function errorMessageNamesTheLocation(testCase)
            try
                ldem.schema.parseQuantity("3 kg", "length", "case.ldem:7 [mesh] module_size");
                testCase.verifyFail('An error was expected.');
            catch err
                testCase.verifySubstring(err.message, 'case.ldem:7 [mesh] module_size');
                testCase.verifySubstring(err.message, 'mm');
            end
        end

        function formatsReadableUnits(testCase)
            format = @ldem.schema.formatQuantity;
            testCase.verifyEqual(format(3.5e-7, "time"), "0.35 us");
            testCase.verifyEqual(format(2.8e-3, "time"), "2.8 ms");
            testCase.verifyEqual(format(0.015, "time"), "15 ms");
            testCase.verifyEqual(format(0.003, "length"), "3 mm");
            testCase.verifyEqual(format(3.87e9, "pressure"), "3.87 GPa");
            testCase.verifyEqual(format(1500, "density"), "1500 kg/m3");
            testCase.verifyEqual(format(0, "time"), "0 s");
            testCase.verifyEqual(format(24.5, "modules"), "24.5 modules");
        end

        function formatThenParseGivesTheSameValue(testCase)
            values = [1e-3 0.003 3.5e-7 2.8e-3 0.015 4.5e-3 3.87e9 32e9 0.1385 1/3 pi*1e-5 123456789.123 5e-10];
            for dimension = ["length" "time" "pressure" "density" "rate" "toughness" "number"]
                for v = values
                    text = ldem.schema.formatQuantity(v, dimension);
                    testCase.verifyEqual(ldem.schema.parseQuantity(text, dimension), v, ...
                        "Round trip of " + string(v) + " as " + dimension + ": " + text);
                end
            end
        end

        function shortestTextRoundTrips(testCase)
            for x = [0 1 -4 32 0.1 3.5e-7 1/3 2/3 1e15 1e-300 123456.789]
                testCase.verifyEqual(str2double(ldem.schema.shortestText(x)), x);
            end
            testCase.verifyEqual(ldem.schema.shortestText(0.1), "0.1");
            testCase.verifyEqual(ldem.schema.shortestText(32), "32");
        end

        function suggestsCloseWordsOnly(testCase)
            words = ["young_modulus" "density" "poisson_ratio"];
            testCase.verifySubstring(ldem.schema.suggest("young_modulos", words), "young_modulus");
            testCase.verifyEqual(ldem.schema.suggest("zzzzzzzz", words), "");
        end
    end
end
