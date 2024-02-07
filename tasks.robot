*** Settings ***
Library     RPA.Browser.Selenium    auto_close=${FALSE}
Library     RPA.PDF
Library     RPA.HTTP
Library     RPA.Tables
Library     OperatingSystem
Library     DateTime
Library     Dialogs
Library     Screenshot
Library     RPA.Archive
Library     RPA.Robocorp.Vault


*** Variables ***
${order_csv_url}            https://robotsparebinindustries.com/orders.csv
${local_file}               orders.csv
${robot_order_website}      https://robotsparebinindustries.com/#/robot-order
${locator_order_number}     css:.badge.badge-success
${receipt_dir}=             ${OUTPUT_DIR}${/}receipts/
${image_dir}=               ${OUTPUT_DIR}${/}screenshots/
${zip_directory}=           ${OUTPUT_DIR}${/}


*** Tasks ***
Complete Order Process
    Open The Robot Order Website
    Download Orders File
    Close Annoying Modal
    Fill The Form using CSV
    ZIP
    ZIPP    $zip_file


*** Keywords ***
Open The Robot Order Website
    Open Available Browser    ${robot_order_website}

Download Orders File
    Download    ${order_csv_url}    ${local_file}    overwrite=True

Fill The Form using CSV
    ${orders}=    Read table from CSV    ${local_file}
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds    50    0.1    Fill out order Form    ${order}
        Save order details
        Return to Order Form
        Close Annoying Modal
    END

Close Annoying Modal
    Click Button    OK

Click Order
    Click Button    Order

Return to Order Form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Fill Out Order Form
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:order
    ${error_visible}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible
    ...    css:.alert.alert-danger[role='alert']
    IF    ${error_visible}    Click Button    id:order
    ${order_success}=    Run Keyword And Return Status    Save Order Details
    RETURN    ${order_success}

Save Order Details
    Wait Until Element Is Visible    id:receipt
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_dir}receipt_${orderid}.pdf
    ${receipt_element}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_element}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_dir}robot_${orderid}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Merge PDF and Image    ${receipt_filename}    ${image_filename}

Merge PDF and Image
    [Arguments]    ${receipt}    ${image}
    Open PDF    ${receipt}
    @{pseudo_file_list}=    Create List
    ...    ${receipt}
    ...    ${image}

    Add Files To PDF    ${pseudo_file_list}    ${receipt}    ${False}
    Close Pdf    ${receipt}

ZIP
    ${date}=    Get Current Date
    ${zip_file}=    Set Variable    zip_receipts_images
    Log To Console    ${zip_file}_${date}
    ZIPP    ${zip_file}_${date}

ZIPP
    [Arguments]    ${zip_file}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_dir_}    ${zip_directory}${zip_file}
