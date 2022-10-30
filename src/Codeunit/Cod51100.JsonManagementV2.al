codeunit 51100 "JSON Management V2"
{
    //This method receives any Record using the Variant data type and converts it to Json format.
    procedure RecordToJson(Rec: Variant): JsonObject
    var
        FieldRef: FieldRef;
        JORecord: JsonObject;
        JSONFieldArray: JsonArray;
        RecordRef: RecordRef;
        i: Integer;
    begin
        //Gets the table of a Record variable and causes the RecordRef to refer to the same table.
        RecordRef.GetTable(Rec);

        //We create the header of the Record with information of Record Number, 
        //Record Name, Company, Company, Position, RecordId and its Primary Key.
        JORecord.Add('id', RecordRef.Number());
        JORecord.Add('name', DelChr(RecordRef.Name(), '=', ' /.-*+'));
        JORecord.Add('company', RecordRef.CurrentCompany());
        JORecord.Add('position', RecordRef.GetPosition(true));
        JORecord.Add('recordId', Format(RecordRef.RecordId()));
        JORecord.Add('primaryKey', PrimaryKeyToJson(RecordRef));

        //We go through all the fields of the RecordRef
        for i := 1 to RecordRef.FieldCount do begin

            FieldRef := RecordRef.FieldIndex(i);

            //Each Field we loop through we get its Field Id, Field Name, Field Type and its Value.
            //and then we store it in a json array
            JSONFieldArray.Add(FieldToJson(FieldRef));
        end;

        JORecord.Add('fields', JSONFieldArray);
        exit(JORecord);
    end;

    //This method allows us to separately obtain the Key of a respective Record in Json format.
    procedure PrimaryKeyToJson(RecRef: RecordRef): JsonObject
    var
        FR_PrimaryKey: FieldRef;
        KeyRef_PrimaryKey: KeyRef;
        JO_PrimaryKey: JsonObject;
        JO_Key: JsonArray;
        i: Integer;
    begin
        KeyRef_PrimaryKey := RecRef.KeyIndex(1);
        for i := 1 to KeyRef_PrimaryKey.FieldCount() do begin
            FR_PrimaryKey := KeyRef_PrimaryKey.FieldIndex(i);
            JO_Key.Add(FieldToJson(FR_PrimaryKey));
        end;

        JO_PrimaryKey.Add('fieldCount', KeyRef_PrimaryKey.FieldCount());
        JO_PrimaryKey.Add('fields', JO_Key);
        exit(JO_PrimaryKey);
    end;

    //This method allows us to create the structure Id, Name, Type and Value of each field of a Record.
    procedure FieldToJson(FieldRef: FieldRef): JsonObject
    var
        JSONProperty: JsonObject;
    begin
        JSONProperty.Add('id', FieldRef.Number());
        JSONProperty.Add('name', DelChr(FieldRef.Name(), '=', ' /.-*+'));
        JSONProperty.Add('type', Format(FieldRef.Type()));
        JSONProperty.Add('value', FieldToJsonValue(FieldRef));

        exit(JSONProperty);
    end;

    //This method allows us to obtain the value of a FieldRef.
    local procedure FieldToJsonValue(FieldRef: FieldRef): JsonValue
    var
        FieldValue: JsonValue;
        BoolValue: Boolean;
        IntValue: Integer;
        DecimalValue: Decimal;
        DateValue: Date;
        TimeValue: Time;
        DateTimeValue: DateTime;
        DurationValue: Duration;
        BigIntegerValue: BigInteger;
        GuidValue: Guid;
        RecordRefField: RecordRef;
    begin
        if (FieldRef.Class() = FieldClass::FlowField) then
            FieldRef.CalcField();

        if (FieldRef.Type() <> FieldType::Boolean) and (not HasValue(FieldRef)) then begin
            FieldValue.SetValueToNull();
            exit(FieldValue);
        end;

        case FieldRef.Type() of
            FieldType::Boolean:
                begin
                    BoolValue := FieldRef.Value();
                    FieldValue.SetValue(BoolValue);
                end;
            FieldType::Integer:
                begin
                    IntValue := FieldRef.Value();
                    FieldValue.SetValue(IntValue);
                end;
            FieldType::Decimal:
                begin
                    DecimalValue := FieldRef.Value();
                    FieldValue.SetValue(DecimalValue);
                end;
            FieldType::Date:
                begin
                    DateValue := FieldRef.Value();
                    FieldValue.SetValue(DateValue);
                end;
            FieldType::Time:
                begin
                    TimeValue := FieldRef.Value();
                    FieldValue.SetValue(TimeValue);
                end;
            FieldType::DateTime:
                begin
                    DateTimeValue := FieldRef.Value();
                    FieldValue.SetValue(DateTimeValue);
                end;
            FieldType::Duration:
                begin
                    DurationValue := FieldRef.Value();
                    FieldValue.SetValue(DurationValue);
                end;
            FieldType::BigInteger:
                begin
                    BigIntegerValue := FieldRef.Value();
                    FieldValue.SetValue(BigIntegerValue);
                end;
            FieldType::Guid:
                begin
                    GuidValue := FieldRef.Value();
                    FieldValue.SetValue(GuidValue);
                end;
            FieldType::MediaSet:
                begin
                    RecordRefField := FieldRef.Record();
                    FieldValue.SetValue(GetBase64(RecordRefField.Number, FieldRef));
                end;
            FieldType::Media:
                begin
                    RecordRefField := FieldRef.Record();
                    FieldValue.SetValue(GetBase64(RecordRefField.Number, FieldRef));
                end;
            else
                FieldValue.SetValue(Format(FieldRef.Value()));
        end;

        exit(FieldValue);
    end;

    //GetBase64: We use it to convert the images of the tables Vendor, Customer, Item, Employee in base 64.
    local procedure GetBase64("Table ID": Integer; FieldRef: FieldRef): Text
    var
        RecordRefImage: RecordRef;
        Base64: Codeunit "Base64 Convert";
        TenantMedia: Record "Tenant Media";
        ItemRec: Record Item;
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
        EmployeeRec: Record Employee;
        TextOutput: Text;
        InStream: InStream;
    begin

        case "Table ID" of
            DATABASE::Item:
                begin
                    RecordRefImage := FieldRef.Record();
                    ItemRec.Get(RecordRefImage.RecordId);
                    if (ItemRec.Picture.Count > 0) then begin
                        if TenantMedia.Get(ItemRec.Picture.Item(1)) then begin
                            TenantMedia.CalcFields(Content);
                            if TenantMedia.Content.HasValue() then begin
                                TenantMedia.Content.CreateInStream(InStream, TextEncoding::WINDOWS);
                                TextOutput := Base64.ToBase64(InStream);
                                exit(TextOutput);
                            end;
                        end else begin
                            TextOutput := 'NOIMAGE';
                            exit(TextOutput);
                        end;
                    end else begin
                        TextOutput := 'NOIMAGE';
                        exit(TextOutput);
                    end;
                end;
            DATABASE::Customer:
                begin
                    RecordRefImage := FieldRef.Record();
                    CustomerRec.Get(RecordRefImage.RecordId);
                    if (CustomerRec.Image.HasValue) then begin
                        if TenantMedia.Get(CustomerRec.Image.MediaId) then begin
                            TenantMedia.CalcFields(Content);
                            if TenantMedia.Content.HasValue() then begin
                                TenantMedia.Content.CreateInStream(InStream, TextEncoding::WINDOWS);
                                TextOutput := Base64.ToBase64(InStream);
                                exit(TextOutput);
                            end;
                        end else begin
                            TextOutput := 'NOIMAGE';
                            exit(TextOutput);
                        end;
                    end else begin
                        TextOutput := 'NOIMAGE';
                        exit(TextOutput);
                    end;
                end;
            DATABASE::Vendor:
                begin
                    RecordRefImage := FieldRef.Record();
                    VendorRec.Get(RecordRefImage.RecordId);
                    if (VendorRec.Image.HasValue) then begin
                        if TenantMedia.Get(VendorRec.Image) then begin
                            TenantMedia.CalcFields(Content);
                            if TenantMedia.Content.HasValue() then begin
                                TenantMedia.Content.CreateInStream(InStream, TextEncoding::WINDOWS);
                                TextOutput := Base64.ToBase64(InStream);
                                exit(TextOutput);
                            end;
                        end else begin
                            TextOutput := 'NOIMAGE';
                            exit(TextOutput);
                        end;
                    end else begin
                        TextOutput := 'NOIMAGE';
                        exit(TextOutput);
                    end;
                end;
            DATABASE::Employee:
                begin
                    RecordRefImage := FieldRef.Record();
                    EmployeeRec.Get(RecordRefImage.RecordId);
                    if (EmployeeRec.Image.HasValue) then begin
                        if TenantMedia.Get(EmployeeRec.Image) then begin
                            TenantMedia.CalcFields(Content);
                            if TenantMedia.Content.HasValue() then begin
                                TenantMedia.Content.CreateInStream(InStream, TextEncoding::WINDOWS);
                                TextOutput := Base64.ToBase64(InStream);
                                exit(TextOutput);
                            end;
                        end else begin
                            TextOutput := 'NOIMAGE';
                            exit(TextOutput);
                        end;
                    end else begin
                        TextOutput := 'NOIMAGE';
                        exit(TextOutput);
                    end;
                end;
            else begin
                TextOutput := 'Not Handled'
            end;

        end;
    end;

    procedure HasValue(FieldRef: FieldRef): Boolean
    var
        HasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FieldRef.Type() of
            FieldType::Boolean:
                HasValue := FieldRef.Value();
            FieldType::Option:
                HasValue := true;
            FieldType::Integer:
                begin
                    Int := FieldRef.Value();
                    HasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FieldRef.Value();
                    HasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FieldRef.Value();
                    HasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FieldRef.Value();
                    HasValue := T <> 0T;
                end;
            FieldType::Blob:
                HasValue := false;
            else
                HasValue := Format(FieldRef.Value()) <> '';
        end;

        exit(HasValue);
    end;

}