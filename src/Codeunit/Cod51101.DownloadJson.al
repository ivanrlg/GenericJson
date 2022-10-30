codeunit 51101 DownloadJson
{
    trigger OnRun()
    begin
    end;

    //This is an auxiliary method used, on the one hand, to go through all the records of a respective Record/Table,
    //and on the other hand, to allow Business Central to allow the user to download it locally.
    procedure DownloadJson(Variant: Variant)
    var
        JSONManagementV2: Codeunit "JSON Management V2";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        Confirmed: Boolean;
        Istream: InStream;
        mJsonArray: JsonArray;
        OStream: OutStream;
        JsonText, FileName : text;
    begin
        //Gets the table of a Record variable and causes the RecordRef to refer to the same table.
        RecordRef.GetTable(Variant);

        FileName := RecordRef.Name + '.json';

        Confirmed := Dialog.Confirm('Do you want Download the file ' + FileName + ' ?');
        if (not Confirmed) then
            exit;

        //We iterate all the records of the table
        if RecordRef.FindSet() then
            repeat
                //Each Json obtained is stored in an Array of Json.
                mJsonArray.Add(JSONManagementV2.RecordToJson(Variant));
            until RecordRef.Next() = 0;

        mJsonArray.WriteTo(JsonText);

        TempBlob.CreateOutStream(OStream, TEXTENCODING::UTF8);
        OStream.WriteText(JsonText);
        TempBlob.CreateInStream(Istream);

        //We download locally.
        DownloadFromStream(Istream, 'Export', '', 'All Files (*.*)|*.*', FileName);
    end;
}