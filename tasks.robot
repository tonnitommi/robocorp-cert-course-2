*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${SITE_URL}                    https://robotsparebinindustries.com/#/robot-order
${FILE_URL}                    https://robotsparebinindustries.com/orders.csv
${DOWNLOAD_PATH}               ${OUTPUT DIR}${/}temp${/}orders.csv
${GLOBAL_RETRY_AMOUNT}         5x
${GLOBAL_RETRY_INTERVAL}       0.5s

*** Tasks ***
Order robots from RobotSpareBin Industries
    Open the robot order website
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close annoying modal
        Fill the form     ${row}
        Preview the robot
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Submit the order
        ${pdf}=    Store the receipt as PDF    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the screenshot to the PDF    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close All Browsers

*** Keywords ***
Open the robot order website
    Open Available Browser    ${SITE_URL}

Get Orders
    Download    ${FILE_URL}    ${DOWNLOAD_PATH}
    ${orders}=    Read table from CSV    ${DOWNLOAD_PATH}
    [Return]    ${orders}

Close annoying modal
    Wait Until Page Contains Element    alias:Alertbuttons
    TRY
        Click Element    alias:BtnOK
    EXCEPT
        No Operation
    END

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    alias:inputLegs    3
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Element    id:preview
    Wait Until Page Contains Element    id:robot-preview-image

Submit the order
    Click Element    id:order
    Page Should Contain Element    id:receipt

Store the receipt as PDF
    [Arguments]    ${order_number}
    ${receipt_element}=     Get Element Attribute     id:receipt     outerHTML
    Html To Pdf    ${receipt_element}    ${OUTPUT DIR}${/}temp${/}${order_number}.pdf     overwrite=True
    [Return]    ${OUTPUT DIR}${/}temp${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT DIR}${/}temp${/}${order_number}.png
    [Return]    ${OUTPUT DIR}${/}temp${/}${order_number}.png

Embed the screenshot to the PDF
    [Arguments]    ${pdf}    ${screenshot}
    Add Watermark Image To PDF
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=${pdf}
    Close All Pdfs

Go to order another robot
    Click Element    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${OUTPUT DIR}${/}temp
    ...    ${OUTPUT DIR}${/}receipts.zip
    ...    include=*.pdf