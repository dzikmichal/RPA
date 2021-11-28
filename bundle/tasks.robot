*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images
Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.FileSystem
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***   

# +
*** Keywords ***
Ask For User Input
	Add Heading			CSV File
    Add Text Input		URL		placeholder=Enter the CSV file URL
    ${url}=		Run Dialog
    [Return]	${url.URL}
Open Robot Order Website
    ${secret}=      Get Secret    website
    Open Available Browser   ${secret}[address]
Get Orders
	${csv_address}=		Ask For User Input
    Download    ${csv_address}    overwrite=True
    ${table}=   Read table from CSV    orders.csv
    [Return]    ${table}
Close Popup
    Click Element    class:btn-dark
Submit Robot Order
    FOR    ${i}    IN RANGE    10
        Click Button           order
        ${receipt_presence}=    Does Page Contain Element    id:receipt
        Exit For Loop If       ${receipt_presence}
    END


Fill Single Form
    [Arguments]                     ${row}
    Select From List By Value       id:head                 ${row}[Head]
    Select Radio Button             body                    ${row}[Body]
    Input Text                      class:form-control      ${row}[Legs]
    Input Text                      address                 ${row}[Address]
    Click Button                    preview
    Submit Robot Order
    ${receipt}=     Get Element Attribute    receipt    outerHTML
    Html To Pdf     ${receipt}               ${CURDIR}${/}output${/}receipts${/}receipt(${row}[Order number]).pdf
    Screenshot      robot-preview-image      ${CURDIR}${/}output${/}img${/}robot-preview-image(${row}[Order number]).png
    Open Pdf                        ${CURDIR}${/}output${/}receipts${/}receipt(${row}[Order number]).pdf
    Add Watermark Image To Pdf      ${CURDIR}${/}output${/}img${/}robot-preview-image(${row}[Order number]).png    ${CURDIR}${/}output${/}receipts${/}receipt(${row}[Order number]).pdf   
    Close Pdf                       ${CURDIR}${/}output${/}receipts${/}receipt(${row}[Order number]).pdf
    Click Button        order-another

Zip Receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts${/}    ${CURDIR}${/}output${/}receipts.zip
    
    
    


# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
	${orders}=  Get Orders
    Open Robot Order Website
    FOR  ${row}     IN     @{orders}
        Close Popup
        Fill Single Form    ${row}
    END
    Zip Receipts
    
    [Teardown]  Close All Browsers


