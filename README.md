# figma-api-hx  
## Haxe Figma API
 - Automatically extracts [Figma API](https://www.figma.com/developers/docs) 
 - Full types and enums support.
 - Comments & other endpoints support in the next update.
## Example
```haxe
var figmaAPI:FigmaAPI = new FigmaAPI(FIGMA_TOKEN);
figmaAPI.files(FILE_KEY, { geometry:FilesGeometry.PATHS }, function(r:Response<Document>) {
	trace(r.data.name); 
	trace(r.data.lastModified); 
	...
});
```
