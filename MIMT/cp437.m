function outtext = cp437(intext,rev)
%  OUTTEXT=CP437(INTEXT,{REV})
%     Simulate the use of IBM CP437 as utilized by textim().
%     Input text is converted to UTF8 characters visually
%     corresponding to those in CP437. 
%
%  INTEXT is a character or numeric vector in the range [0 255]
%
%  The key 'rev' will reverse the behavior.
%
%  EXAMPLE:
%    print the character set used by textim
%      cs=cp437(0:255);
%    reverse the lookup, converting back to numeric values
%      orig=double(cp437(cs,'rev'));
%
%  See also: textim

% 0,32,255 may appear as the same character in textim (spaces), but they're not really the same
% 0 is null character
% 32 is space
% 255 is nbsp

cp = [0 9786 9787 9829 9830 9827 9824 8226 9688 9675 9689 9794 9792 9834 9835 9788 9658 9668 8597 8252 182 167 9644 8616 8593 8595 8594 8592 8735 8596 9650 9660 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 8962 199 252 233 226 228 224 229 231 234 235 232 239 238 236 196 197 201 230 198 244 246 242 251 249 255 214 220 162 163 165 8359 402 225 237 243 250 241 209 170 186 191 8976 172 189 188 161 171 187 9617 9618 9619 9474 9508 9569 9570 9558 9557 9571 9553 9559 9565 9564 9563 9488 9492 9524 9516 9500 9472 9532 9566 9567 9562 9556 9577 9574 9568 9552 9580 9575 9576 9572 9573 9561 9560 9554 9555 9579 9578 9496 9484 9608 9604 9612 9616 9600 945 223 915 960 931 963 181 964 934 920 937 948 8734 966 949 8745 8801 177 8805 8804 8992 8993 247 8776 176 8729 183 8730 8319 178 9632 160];
if ~exist('rev','var')
	outtext = char(cp(intext+1));
else
	[a idx] = ismember(double(intext),cp);
	outtext = char(idx);
end



