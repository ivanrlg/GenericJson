pageextension 51101 "Item Ext" extends "Item List"
{
    actions
    {
        addafter(Reports)
        {
            action(DownloadJson)
            {
                ApplicationArea = Suite;
                Caption = 'Download Json';
                Image = XMLFile;
                Promoted = true;
                PromotedCategory = Report;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    DownloadJson: Codeunit DownloadJson;
                begin
                    DownloadJson.DownloadJson(Rec);
                end;
            }
        }
    }
}
