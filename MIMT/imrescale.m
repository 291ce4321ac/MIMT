function outpict = imrescale(inpict,ca,cb)
%  OUTPICT = IMRESCALE(INPICT)
%  OUTPICT = IMRESCALE(INPICT,OUTRANGE)
%  OUTPICT = IMRESCALE(INPICT,INRANGE,OUTRANGE)
%     Rescale data based on the assertion of the nominal input and output
%     data range.  
%     Unlike common tools, IMRESCALE allows the use of class names for implicit 
%     range specification.  Unlike IMCAST, the class of INPICT is ignored,  
%     and the output class is 'double' regardless of the value of OUTCLASS.
%     IMRESCALE only rescales data.  This may be convenient for scaling threshold 
%     values to match the class of an image, instead of rescaling the entire image.
%
%  INPICT is an image or array of any shape or numeric/logical class.
%  INRANGE and OUTRANGE specify the nominal input and output range of the data.
%     Either may be a 2-element vector explicitly specifying a range, or either 
%     may be a class name implicitly specifying the nominal range associated with
%     a particular numeric class.  Supported class names are those supported
%     by imclassrange().
%     When unspecified, INRANGE is implied by the class of INPICT.
%     When unspecified, OUTRANGE is implied by the class of OUTPICT (i.e. [0 1])
%
%  Note that this is a simple linear scaling and offset.  Since no rounding is 
%  performed, the results obtained from imcast() and imrescale() may differ. 
%  For example, when scaling to 'int16' when using implicit range specification, 
%  the result will occasionally differ from true integer output by as much as 0.5.  
%  Using int16(round(imrescale(...,'int16')+32768)-32768) rounds as expected for 
%  this case, though generally, it's probably best to avoid needing to use 
%  imrescale() like this.
%
%  Output class is 'double'
%
%  See also: imcast, simnorm
	
switch nargin
	case 1
		inrg = getrange(class(inpict));
		outrg = [0 1];
	case 2
		inrg = getrange(class(inpict));
		outrg = getrange(ca);
	case 3
		inrg = getrange(ca);
		outrg = getrange(cb);
	otherwise
		error('IMRESCALE: incorrect number of arguments')
end

outpict = (outrg(2)-outrg(1))*(double(inpict)-inrg(1))/(inrg(2)-inrg(1))+outrg(1);

function thisrange = getrange(x)
	if isnumeric(x)
		thisrange = double(x);
	elseif ischar(x)
		thisrange = imclassrange(x);
	end
end

end



