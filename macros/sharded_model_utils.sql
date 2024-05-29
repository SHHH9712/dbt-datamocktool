{% macro generate_sharded_model_name(alias_name=model.name) %}
     {{ alias_name }}_{{ var('company_group') }}_{{ var('dateid_suffix') }}_{{ var('batch_part_id') }}
{% endmacro %}

{% macro generate_sharded_model_name_exclude_batch_id(alias_name=model.name) %}
     {{ alias_name }}_{{ var('company_group') }}_{{ var('dateid_suffix') }}
{% endmacro %}

{% macro generate_sharded_model_name_previous_day(alias_name=model.name) %}
     {%- set company_group -%} {{ var("company_group", "None") }} {%- endset -%}
     {%- set batch_part_id -%} {{ var("batch_part_id", "None") }} {%- endset -%}
     {% set prev_day_sql %}
      SELECT FORMAT_DATE('%Y%m%d',DATE_SUB({{ var('dateid') }}, INTERVAL 1 DAY)) prev_dt
     {% endset %}
     {% set results = run_query(prev_day_sql) %}
     {% if execute %}
          {% set first_row = results.rows[0] %}
          {% set dateid_suffix_prev = first_row['prev_dt'] %}
    {% endif %}
    {% set table_name_prev = alias_name ~ '_' ~ company_group ~ '_' ~ dateid_suffix_prev ~ '_' ~ batch_part_id | trim %}
    {{ table_name_prev }}
{% endmacro %}

{% macro generate_model_target_dataset(schema_suffix='_maestro') %}
     {%- set namespace -%} {{ var("namespace","None") }} {%- endset -%}
     {%- set is_uni -%} {{ var("is_uni", "False") }} {%- endset -%} 
     {%- set uni_bq_project -%} {{ var("uni_bq_project", "None") }} {%- endset -%}
     {%- set integration_test_suffix -%} {{ var("integration_test_dataset_suffix", "") }} {%- endset -%} 
     {%- set target_schema = target.schema ~ (('_' ~ integration_test_suffix) if integration_test_suffix != "" else "") %}

     {% if is_uni!="True" %}
          {% set tgt_dataset = target.project ~ '.' ~ target_schema ~ schema_suffix  | trim %}
     {% elif is_uni=="True" and namespace!="None" %}
          {% set tgt_dataset = uni_bq_project ~ '.' ~ target_schema ~ schema_suffix ~ '_' ~ namespace | trim %}
     {% else %}
          {% set tgt_dataset = uni_bq_project ~ '.' ~ target_schema | trim %}
    {% endif %}

    {{ tgt_dataset }}

{% endmacro %}

{% macro get_maestro_sharded_table_name_current(alias_name=model.name,schema_suffix='_maestro') %}
     `{{ generate_model_target_dataset(schema_suffix) | trim }}`.`{{ generate_sharded_model_name_exclude_batch_id(alias_name) | trim }}_*`
{% endmacro %}

{% macro get_maestro_sharded_table_name_previous(alias_name=model.name) %}
     `{{ generate_model_target_dataset() | trim }}`.`{{ generate_sharded_model_name_previous_day(alias_name) | trim }}`
{% endmacro %}

{% macro get_user_metrics_tbc_company_list() %}
     ('60782f40-26fb-11ee-88bd-efe9941a096e', 'b9f5ea70-01f5-11ed-acb3-17d266045eea')
{% endmacro %}

{% macro get_maestro_target_model_name(alias_name=model.name) %}
     {{alias_name}}_{{ var('maestro_company_config') }}
{% endmacro %}

{% macro get_silver_custom_event_source_table() %}
     {% if var('company_group') == 'openai' %}
          {{ source('prod', 'fct_silver_custom_events_openai') }}
     {% elif var('company_group') == 'flipkart' %}
          {{ source('prod', 'fct_silver_custom_events_flipkart') }}
     {% else %}
          {{ source('prod', 'fct_silver_custom_events') }}
     {% endif %}
{% endmacro %}
