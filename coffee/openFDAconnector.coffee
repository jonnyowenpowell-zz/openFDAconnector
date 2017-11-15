openFDA_api_url = 'https://api.fda.gov/'
openFDA_api_endpoints =
    device_event:       'device/event.json'
    device_recall:      'device/recall.json'
    device_enforcement: 'device/enforcement.json'
openFDA_api_key = 'V4scbZ5YefGvExL5876GSOPjytVTnyBkbxejVkR4'
openFDA_limit = 20

device_event_columns = [
    id: 'mdr_report_key'
    alias: 'id'
    dataType: tableau.dataTypeEnum.int
,
    id: 'adverse_event_flag'
    dataType: tableau.dataTypeEnum.string
,
    id: 'product_problem_flag'
    dataType: tableau.dataTypeEnum.string
,
    id: 'date_of_event'
    dataType: tableau.dataTypeEnum.date
,
    id: 'device_date_of_manufacture'
    dataType: tableau.dataTypeEnum.date
,
    id: 'event_type'
    dataType: tableau.dataTypeEnum.string
, 
    id: 'number_devices_in_event'
    dataType: tableau.dataTypeEnum.int
,
    id: 'number_patients_in_event'
    dataType: tableau.dataTypeEnum.int
,
    id: 'previous_use_code'
    dataType: tableau.dataTypeEnum.string
,
    id: 'remedial_action'
    dataType: tableau.dataTypeEnum.string
,
    id: 'removal_correction_number'
    dataType: tableau.dataTypeEnum.string
,
    id: 'report_number'
    dataType: tableau.dataTypeEnum.string
,
    id: 'single_use_flag'
    dataType: tableau.dataTypeEnum.string
,
    id: 'health_professional'
    dataType: tableau.dataTypeEnum.string
,
    id: 'reprocessed_and_reused_flag'
    dataType: tableau.dataTypeEnum.string
,
    id: 'event_location'
    dataType: tableau.dataTypeEnum.string
]
device_event_schema =
    id: 'device_event'
    alias: 'Device adverse event reports'
    columns: device_event_columns

device_recall_columns = [
    id: 'product_code'
    dataType: tableau.dataTypeEnum.string
,
    id: 'firm_fei_number'
    dataType: tableau.dataTypeEnum.string
,
    id: 'res_event_number'
    dataType: tableau.dataTypeEnum.string
,
    id: 'root_cause_description'
    dataType: tableau.dataTypeEnum.string
,
    id: 'openfda__device_class'
    dataType: tableau.dataTypeEnum.int
]
device_recall_schema =
    id: 'device_recall'
    alias: 'Device recalls'
    columns: device_recall_columns

device_enforcement_columns = [
    id: 'classification'
    dataType: tableau.dataTypeEnum.string
,
    id: 'distribution_pattern'
    dataType: tableau.dataTypeEnum.string
,
    id: 'reason_for_recall'
    dataType: tableau.dataTypeEnum.string
,
    id: 'product_quantity'
    dataType: tableau.dataTypeEnum.string
,
    id: 'voluntary_mandated'
    dataType: tableau.dataTypeEnum.string
,
    id: 'initial_firm_notification'
    dataType: tableau.dataTypeEnum.string
,
    id: 'recall_number'
    dataType: tableau.dataTypeEnum.string
,
    id: 'event_id'
    dataType: tableau.dataTypeEnum.string
,
    id: 'recall_initiation_date'
    dataType: tableau.dataTypeEnum.date
,
    id: 'status'
    dataType: tableau.dataTypeEnum.string
,
    id: 'termination_date'
    dataType: tableau.dataTypeEnum.date
]
device_enforcement_schema =
    id: 'device_enforcement'
    alias: 'Device recall enforcement reports'
    columns: device_enforcement_columns

openFDA_connector = tableau.makeConnector()

openFDA_connector.getSchema = (schema_callback) ->
    schema_callback [device_event_schema, device_recall_schema, device_enforcement_schema]
    return
    
openFDA_connector.getData = (table, done_callback) ->
    $.ajaxSetup
    data:
        api_key: openFDA_api_key
        dataType: 'json'
        error: (jqXHR, text_status, error_thrown) ->
            alert 'Some kind of ajax error! Error status: ' + text_status + ', Error: ' + error_thrown
            return

    flatten = (data) ->
        result = {}
        recurse = (cur, prop) ->
            if Object(cur) != cur
                result[prop] = cur
            else if Array.isArray(cur)
                recurse(cur[i], if i == 0 then prop else prop + '[' + i + ']') for i in [0..cur.length] 
                if cur.length == 0
                  result[prop] = []
            else
                isEmpty = true;
                for p of cur
                    isEmpty = false;
                    recurse(cur[p], if prop then prop+'__'+p else p);
                if isEmpty and prop
                    result[prop] = {}
            return 
        recurse data, ''
        result
    
    process_response = (response) ->
        response = response.results
        table_data = []
        add_row = (row) ->
            row_data = {}
            row = flatten row 
            process_data = (column) ->
                row_data[column.id] = switch
                    when column.dataType == tableau.dataTypeEnum.int and column.id.includes 'number'
                        row_data[column.id] = (parseInt row[column.id] or 1)
                    when column.dataType == tableau.dataTypeEnum.int
                        row_data[column.id] = parseInt row[column.id]
                    when column.dataType == tableau.dataTypeEnum.date
                        row_data[column.id] = if not row[column.id] then null else new Date Date.UTC row[column.id][0..3], (parseInt row[column.id][4..5]) - 1, row[column.id][6..7]
                    else
                        row_data[column.id] = row[column.id] or null
            process_data column for column in table.tableInfo.columns
            table_data.push row_data
            return
        add_row row for row in response
        table.appendRows table_data
        done_callback()
        return
    
    $.ajax
        url: openFDA_api_url + openFDA_api_endpoints[table.tableInfo.id]
        data:
            limit: openFDA_limit
            skip: 0
        success: process_response
    return

tableau.registerConnector(openFDA_connector)

$(document).ready ->
    $('#submitButton').click ->
        tableau.connectionName = 'OpenFDA Devices Database'
        tableau.submit()
        return
    return


