function im2ods(inpict,archive,pixelsize,imwidth,palsize)
%   IM2ODS(INPICT, OUTPATH, PIXELSIZE, IMWIDTH, {PALSIZE})
%       create an ODS spreadsheet (open office/libre office)
%       using colored cells to replicate an image
%
%   INPICT is a color image
%   OUTPATH is the name of the output .ods file
%   PIXELSIZE is the size of the spreadsheet cells
%   IMWIDTH is the image width in columns
%   PALSIZE is the palette size (default=255)
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/im2ods.html

if ~exist('palsize','var')
    palsize = 255;
end

templatedir = fullfile(fileparts(mfilename('fullpath')),'template4ods');

archivelist = cell(8,1);
archivelist(1) = cellstr(fullfile(templatedir, 'Thumbnails'));
archivelist(2) = cellstr(fullfile(templatedir, 'META-INF'));
archivelist(3) = cellstr(fullfile(templatedir, 'Configurations2'));
archivelist(4) = cellstr(fullfile(templatedir, 'content.xml'));
archivelist(5) = cellstr(fullfile(templatedir, 'styles.xml'));
archivelist(6) = cellstr(fullfile(templatedir, 'settings.xml'));
archivelist(7) = cellstr(fullfile(templatedir, 'meta.xml'));
archivelist(8) = cellstr(fullfile(templatedir, 'mimetype'));
outfile = fullfile(templatedir, 'content.xml');

header = '<?xml version="1.0" encoding="UTF-8"?><office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table" xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0" xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0" xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0" xmlns:css3t="http://www.w3.org/TR/css3-text/" office:version="1.2"><office:scripts/><office:font-face-decls><style:font-face style:name="Arial" svg:font-family="Arial" style:font-family-generic="swiss" style:font-pitch="variable"/><style:font-face style:name="DejaVu Sans" svg:font-family="&apos;DejaVu Sans&apos;" style:font-family-generic="system" style:font-pitch="variable"/><style:font-face style:name="Lohit Hindi" svg:font-family="&apos;Lohit Hindi&apos;" style:font-family-generic="system" style:font-pitch="variable"/></office:font-face-decls><office:automatic-styles>';
colstyle = '<style:style style:name="co1" style:family="table-column"><style:table-column-properties fo:break-before="auto" style:column-width="SIZEin"/></style:style>';
rowstyle = '<style:style style:name="ro1" style:family="table-row"><style:table-row-properties style:row-height="SIZEin" fo:break-before="auto" style:use-optimal-row-height="false"/></style:style>';
tabstyle = '<style:style style:name="ta1" style:family="table" style:master-page-name="Default"><style:table-properties table:display="true" style:writing-mode="lr-tb"/></style:style>';
celstyle = '<style:style style:name="ceNNN" style:family="table-cell" style:parent-style-name="Default"><style:table-cell-properties fo:background-color="#HEXCOLOR"/></style:style>';
tabhead = '</office:automatic-styles><office:body><office:spreadsheet><table:table table:name="Sheet1" table:style-name="ta1">';
colhead = '<table:table-column table:style-name="co1" table:number-columns-repeated="NNN" table:default-cell-style-name="Default"/>';
rowhead = '<table:table-row table:style-name="ro1">';
cellcontent = '<table:table-cell table:style-name="ceNNN"/>';
rowtail = '</table:table-row>';
tabtail = '</table:table><table:named-expressions/></office:spreadsheet></office:body></office:document-content>';

inpict = imresizeFB(inpict,[NaN imwidth]);
insize = size(inpict);

[indexedpict,map] = rgb2ind(inpict,palsize,'nodither');
pal = cell(length(map(:,1)),1);
for x = 1:1:length(map(:,1));
    tempc = dec2hex(map(x,:)*255);
    if (length(tempc(1,:)) == 2);
        color = [tempc([1 4]) tempc([2 5]) tempc([3 6])];
    else
        color = ['0' tempc(1) '0' tempc(2) '0' tempc(3)];
    end
    
    pal(x) = cellstr(color);
end

fid = fopen(outfile, 'wt'); 
fprintf(fid, '%s\n', header);
fprintf(fid, '%s\n', strrep(colstyle, 'SIZE', num2str(pixelsize)));
fprintf(fid, '%s\n', strrep(rowstyle, 'SIZE', num2str(pixelsize)));
fprintf(fid, '%s\n', tabstyle);

for x = 1:1:length(pal);
    fprintf(fid, '%s\n', strrep(strrep(celstyle,'NNN',num2str(x)), ...
        'HEXCOLOR',char(pal(x))));
end

fprintf(fid, '%s\n', tabhead);
fprintf(fid, '%s\n', strrep(colhead,'NNN',num2str(insize(2))));

for y = 1:1:insize(1);
    fprintf(fid, '%s\n', rowhead);
    for x = 1:1:insize(2);
        fprintf(fid, '%s\n', strrep(cellcontent, ...
        'NNN',num2str(indexedpict(y,x)+1)));
    end
    fprintf(fid, '%s\n', rowtail);
end

fprintf(fid, '%s\n', tabtail);
fclose(fid);

zip(archive,archivelist);
movefile([archive '.zip'], archive);

return

