# datamocktool

## About
datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Quickstart
1. Install this package following the guide in the [dbt documentation](https://docs.getdbt.com/docs/building-a-dbt-project/package-management).
2. Create your mock CSVs: sample inputs for your models and the expected outputs of those models given the inputs.
    * Save them to your seeds directory (usually `data/`; note that you can use any folder structure you would like within that directory)
    * See the `integration_tests/data/` directory of this project for some examples
3. Map your inputs: Add a variable called `dmt_mappings` to your `dbt_project.yml`. 
    * This variable tells dmt which refs/sources to replace with which seeds when running unit tests
    * Follow the example below.
    * ```yaml
        vars:
          dmt_mappings:
            test_suite_1: # dmt allows you to define multiple test suites so that you can define multiple tests for the same model
              sources:
                raw:
                  customers: dmt__raw_customers_1 # source('raw', 'customers') becomes ref('dmt__raw_customers_1')
                  orders: dbt__raw_orders_1
              models:
                stg_payments: dmt__stg_payments_1 # ref('stg_payments') becomes ref('dmt__stg_payments_1')
                stg_orders: dbt__stg_orders_1
            test_suite_2:
              sources:
                raw:
                  customers: dmt__raw_customers_2
                  orders: dbt__raw_orders_2
              models:
                stg_payments: dmt__stg_payments_2
                stg_orders: dbt__stg_orders_2
4. Define your tests: Add unit tests to your `schema.yml` files, using the following example: 
    * ```yaml
        - name: stg_payments
          tests:
            - dbt_datamocktool.unit_test:
                expected_output: ref('dmt__expected_stg_payments_1') # this should be a CSV of the expected output in your `seeds` directory
                tags: ['test_suite_1']
            - dbt_datamocktool.unit_test:
                expected_output: ref('dmt__expected_stg_payments_2')
                tags: ['test_suite_2']
          columns:
            ...
5. Run your tests: Run the following commands (replacing `test_suite_1` with your test suite name): 
    * `dbt seed`
    * `dbt run -m <YOUR MODELS TO TEST> --vars "dmt_test_suite: test_suite_1"`
    * `dbt test -m tag:test_suite_1`
        