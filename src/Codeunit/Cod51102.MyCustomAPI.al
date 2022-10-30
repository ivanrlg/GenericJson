codeunit 51102 MyCustomAPI
{
    procedure Ping(): Text
    begin
        exit('Pong');
    end;

    //This codeunit is used as a method to be published as webservices and to be able to export
    //the record in json format via Postman/Web App/Azure Functions/Desktop App/Mobile App/Etc.
    procedure GetRecord(jsontext: Text): Text
    var
        Customer: Record Customer;
        Item: Record Item;
        JSONManagementV2: Codeunit "JSON Management V2";
        RecordRef: RecordRef;
        mJsonArray: JsonArray;
        JsonObject: JsonObject;
        NameToken: JsonToken;
        NameRecord: Text;
        Output: Text;
    begin
        JsonObject.ReadFrom(jsontext);

        if not JsonObject.Get('Name', NameToken) then begin
            Error('Error reading Name Record');
        end;

        NameRecord := NameToken.AsValue().AsText();

        case NameRecord of
            'Item':
                begin
                    Item.FindSet();
                    repeat
                        mJsonArray.Add(JSONManagementV2.RecordToJson(Item));
                    until Item.Next() = 0;
                end;

            'Customer':
                begin
                    Customer.FindSet();
                    repeat
                        mJsonArray.Add(JSONManagementV2.RecordToJson(Customer));
                    until Item.Next() = 0;
                end;

        end;

        mJsonArray.WriteTo(Output);

        exit(Output);
    end;

}
