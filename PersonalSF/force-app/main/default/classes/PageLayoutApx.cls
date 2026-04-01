public class PageLayoutApx {
public static void getPageLayoutFields(){
    try{
    List<Metadata.Metadata> layouts = 
    Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                new List<String> {''});

    Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
    for (Metadata.LayoutSection section : layoutMd.layoutSections) {
        for (Metadata.LayoutColumn column : section.layoutColumns) {
        if (column.layoutItems != null) {
        for (Metadata.LayoutItem item : column.layoutItems) {
            System.debug(item.field);
        }
    }
    }
    }
    }
    catch(Exception e){
        system.debug('Exception occured in class PagLayouApx'+ e.getMessage());
    }
}
}