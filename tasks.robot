*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.RobotLogListener

Suite Setup         setup


*** Variables ***
${ROBOT_URL}                https://robotsparebinindustries.com/#/robot-order
${ROBOT_URL_CSV}            https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY}             5x
${GLOBAL_RETRY_INTERVAL}    0.5s
${RECEIPT_FOLDER}           ${OUTPUT_DIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders} =    Get Orders
    Open the robot order website
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY}    ${GLOBAL_RETRY_INTERVAL}    Close the annoying modal
    FOR    ${order}    IN    @{orders}
        Fill the form and keep checking until success    ${order}
        ${pdf} =    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot} =    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Element
        ...    alias:btnOrderAnother
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY}    ${GLOBAL_RETRY_INTERVAL}    Close the annoying modal
    END
    Zip pdf files


*** Keywords ***
Open the robot order website
    Open Available Browser    ${ROBOT_URL}

Get Orders
    Download    ${ROBOT_URL_CSV}    ${OUTPUT_DIR}${/}orders.csv    overwrite=${True}
    ${orders} =    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    header=${True}
    RETURN    ${orders}

Close the annoying modal
    Click Element    alias:btnOk
    Wait Until Element Is Visible    alias:selectHead

Fill the form and keep checking until success
    [Arguments]    ${order}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY}    ${GLOBAL_RETRY_INTERVAL}    Fill the form    ${order}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    alias:selectHead    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    alias:inputLegs    ${order}[Legs]
    Input Text    alias:inputAddress    ${order}[Address]
    Click Element    alias:btnPreview
    Click Element    alias:btnOrder
    Wait Until Element Is Visible    alias:orderReceipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${pdf} =    Set Variable    ${RECEIPT_FOLDER}${/}${order_number}.pdf
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot} =    Set Variable    ${OUTPUT_DIR}${/}${order_number}.png
    Wait Until Element Is Visible    alias:imageRobotPreview
    Screenshot    alias:imageRobotPreview    ${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Create Directory    ${RECEIPT_FOLDER}
    @{files} =    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Zip pdf files
    Archive Folder With Zip
    ...    ${RECEIPT_FOLDER}
    ...    ${OUTPUT_DIR}${/}Pdf.zip

setup
    Log    Setup
