function  outpict = imblend(FG,BG,opacity,blendmode,varargin)
%   IMBLEND(FG, BG, OPACITY, BLENDMODE,{AMOUNT},{COMPMODE},{CAMOUNT},{OPTIONS})
%       Blend and composite images or imagesets as one would blend layers in GIMP, Krita, 
%       or Photoshop. Blending and compositing options are independently configurable.
%
%   FG, BG are image arrays of same H,V dimension
%       Mismatches of dimensions 1:2 are not supported. Use IMSTACKER, IMRESIZE,  
%           IMCROP, or PADARRAY to enforce desired colocation of layer content.
%       Mismatches of dimension 3 are handled by array expansion.  
%           1 or 3 channel images are assumed to be monochrome (I) or RGB, respectively
%           2 or 4 channel images are assumed to have an added alpha channel (IA/RGBA)
%           blending a RGB image and a monochrome image results in an RGB image
%           blending a I/RGB image with a IA/RGBA image results in an image with alpha
%       Mismatches of dimension 4 are handled by array expansion.
%           both can be single images or 4-D imagesets of equal length
%           can also blend a single image with a 4-D imageset
%   OPACITY is a scalar from 0 to 1
%       defines mixing of blended result and original BG
%   BLENDMODE is the desired blend mode name (see list & notes) 
%       this parameter is insensitive to case and spacing
%       see <a href="matlab: web(fullfile(fileparts(which('imblend')),'contour_plots.pdf'))">contour plots</a> for insight into relationships, properties, and scaling behaviors
%   AMOUNT is a numeric blend parameter (optional, default 1)
%       used to internally scale the influence of blend calculations
%       modes which accept this argument are marked with effective range
%   COMPMODE optionally specifies the compositing or alpha blending used for images. (see list)
%       default behavior replicates legacy GIMP behavior
%   CAMOUNT is a thresholding parameter used by some compositing modes (optional, default 1)
%
%   OPTIONS may include the following keys:
%   The user may optionally specify the standard used for luma or YPbPr calculations.
%       This only affects modes which perform Y or YPbPr conversion within the scope of IMBLEND.
%       'rec601' (default) or 'rec709' are valid keys.
%   For niche application, a polar color model can be selected with the 'hsy' or 'ypbpr' keys.
%       Both modes enforce gamut extents via chroma normalization (hsy) or truncation (ypbpr).
%   The user may specify that operations should be done in linear RGB instead of sRGB.  Use
%       'linblend' for blending only, 'lincomp' for composition only, or 'linear' for both.
%   Specifying 'quiet' will suppress non-terminal warnings
%   Specifying 'verbose' will dump extra information relevant for some modes
%   Specifying 'single' will force internal operations to use single-prec FP instead of 'double'.
%       This may not necessarily improve speed, but it is helpful for conserving memory.
%   The user may also perform function transformations where a named mode is unavailable:
%       'invert' inverts the output (i.e. Rinv(FG,BG) = 1-R(FG,BG))
%       'transpose' swaps FG and BG (i.e. Rtpose(FG,BG) = R(BG,FG))
%       'complement' inverts both inputs and output (i.e. Rcomp(FG,BG) = 1-R(1-FG,1-BG))
%       This simplistic wrapper approach may result in AMOUNT behaving in unexpected ways.
%       These blend transformations do not change compositing order.
%       
%   ============================= BLEND MODES =============================
%   Opacity & Composition
%       normal			(compositing only)
%
%   Bidirectional Modes
%   --Contrast & Mixing
%       soft light      (legacy GIMP & GEGL)
%       soft light ps   (Photoshop)
%       soft light svg  (SVG 1.2)
%       soft light eb   (EffectBank/illusions.hu)
%       soft light eb2  (EffectBank/illusions.hu)                    amount:[0 to +inf)
%       overlay         (combined multiply & screen)                 amount:[0 to +inf)
%       hard overlay    (combined multiply & colordodge)
%       hard light      (transpose of overlay)                       amount:[0 to +inf)
%       linear light    (combined lineardodge & linearburn)          amount:[0 1]
%       vivid light     (combined colordodge & colorburn)            amount:[0 to +inf)
%       easy light      (combined easydodge & easyburn)              amount:[0 to +inf)
%       flat light      (combined penumbra a1 & b1)                  amount:[0 to +inf)
%       soft flatlight  (combined penumbra a2 & b2)                  amount:[0 to +inf)
%       softer flatlight (combined penumbra a3 & b3)                 amount:[0 to +inf)
%       mean light      (combined penumbra a1 & b1)                  amount:[0 to +inf)
%       soft mean light (combined penumbra a3 & b3)                  amount:[0 to +inf)
%       star light      (combined star hybrid modes)                 amount:[0 2]
%       moon light      (combined moon hybrid modes)                 amount:[0 2]
%       moon light 2    (combined moon2 hybrid modes)                amount:[0 2]
%       pin light       (combined lightenrgb & darkenrgb)            amount:[0 2]
%       super light     (superelliptic pin light)                    amount:[1 to +inf)
%       fog lighten     (treat FG as its own opacity map)
%       fog darken      (complement of 'bright')
%   --Hard Mix
%       hard mix ps     (Photoshop hard mix)                         amount:[0 2]
%       hard mix kr     (Krita hard mix)                             amount:[0 2]
%       hard mix ib     (IMBLEND hard mix)                           amount:[0 2]
%   --Quadratics
%       glow            (similar to dodge)                           amount:(-inf to +inf)
%       heat            (similar to burn)                            amount:(-inf to +inf)
%       reflect         (glow transpose)                             amount:(-inf to +inf)
%       freeze          (heat transpose)                             amount:(-inf to +inf)
%       helow           (similar to softlight)                       amount:(-inf to +inf)
%       gleat           (similar to vividlight)                      amount:(-inf to +inf)
%       frect           (helow transpose)                            amount:(-inf to +inf)
%       reeze           (gleat transpose)                            amount:(-inf to +inf)
%   --Penumbra
%       penumbra a1     (Jens Gruschel's 'softdodge')                amount:[0 to +inf)
%       penumbra b1     (Jens Gruschel's 'softburn')                 amount:[0 to +inf)
%       penumbra a2     (trig-based version)                         amount:[0 to +inf)
%       penumbra b2     (transpose of 'penumbra a2')                 amount:[0 to +inf)
%       penumbra a3     (improved linearity near FG=BG)              amount:[0 to +inf)
%       penumbra b3     (transpose of 'penumbra a3')                 amount:[0 to +inf) 
%   --Mean-Scaled Contrast
%       scale add       (add bg to fg deviation from mean)           amount:(-inf to +inf)
%       scale mult      (scale bg by mean-normalized fg)             amount:[0 to +inf)
%       contrast        (adjust bg contrast by mean-normalized fg)   amount:[0 to +inf)
%
%   Unidirectional Pairs
%   --Dodges & Burns
%       color dodge     (equivalent to GIMP dodge)                   amount:[0 10]
%       color burn                                                   amount:[0 10]
%       poly dodge      ('colordodge' with nonlinear parameter)      amount:[0 to +inf)
%       poly burn                                                    amount:[0 to +inf)
%       linear dodge    (equivalent to addition)                     amount:[0 1]
%       linear burn                                                  amount:[0 1]
%       easy dodge      (improved detail retention)                  amount:[0 to +inf)
%       easy burn                                                    amount:[0 to +inf)
%       gamma dodge     (stronger than 'easydodge')                  amount:[0 to +inf)
%       gamma burn                                                   amount:[0 to +inf)
%       suau dodge      (unidirectional variant of 'softlighteb2')   amount:[0 to +inf)
%       suau burn                                                    amount:[0 to +inf)
%       maleki dodge    (like a strong, eased 'lineardodge')         amount:[0 1]
%       maleki burn                                                  amount:[0 1]
%   --Hybrid Modes
%       flat glow       (unidirectional variant of 'penumbra a3')    amount:[0 2]
%       flat shadow                                                  amount:[0 2]
%       mean glow       (unidirectional variant of 'average')        amount:[0 2]
%       mean shadow                                                  amount:[0 2]
%       moon glow       (strong, opaque distal response)             amount:[0 2]
%       moon shadow                                                  amount:[0 2]
%       moon glow 2     (reduced central response)                   amount:[0 2]
%       moon shadow 2                                                amount:[0 2]
%       star glow       (increased strength & vividness)             amount:[0 2]
%       star shadow                                                  amount:[0 2]
%   --Krita/IFS Assortment
%       tint            (transpose of 'malekidodge')
%       shade           (complement of 'tint')
%       lighteneb       (like softburn with AMOUNT=0.3)
%       darkeneb        (complement of 'lighteneb')
%
%   Relational
%       lighten RGB     (lighten only (RGB))                         amount:[0 1]
%       darken RGB      (darken only (RGB))                          amount:[0 1]
%       lighten Y       (lighten only (test luma only))              amount:[0 1]
%       darken Y        (darken only (test luma only))               amount:[0 1]
%       saturate        (only increase saturation)                   amount:[0 to +inf)
%       desaturate      (only decrease saturation)                   amount:[0 to +inf)
%       most sat        (select pixels with highest chroma)
%       least sat       (select pixels with lowest chroma)
%       near {layer}	(apply only similar colors)                  amount:[0 1]
%       far {layer}     (transpose of 'near')                        amount:[0 1]
%       replace {layer}   (replace specified regions of FG/BG)       amount:[0 1]
%       preserve {layer}  (logical inverse of 'replacecolor')        amount:[0 1]
%   
%   Mathematic & Technical
%       multiply
%       screen
%       divide
%       addition
%       subtraction
%       bleach          (inverse of addition)
%       stain           (complement of bleach)
%       difference      (abs(M-I))                                   amount:[0 1]
%       equivalence     (inverse of difference)                      amount:[0 1]
%       extremity       (difference with FG inverted)                amount:[0 2]
%       negation        (inverse of extremity)                       amount:[0 2]
%       exclusion       (continuized XOR)
%       interpolate     (cosine interpolation)                       amount:[1 to +inf)
%       hard int        (quantized cosine interpolation)             amount:[1 to +inf)
%       average         (arithmetic mean, linear interpolation)      amount:[0 2]
%       agm             (arithmetic-geometric mean)                  amount:[0 2]
%       geometric       (geometric mean)                             amount:[0 2]
%       ghm             (geometric-harmonic mean)                    amount:[0 2]
%       harmonic        (harmonic mean)                              amount:[0 2]
%       pnorm           (p-norm for p=amount)                        amount:[0 to +inf)
%       sqrtdiff        (difference of square roots)                 amount:[-1 1]
%       arctan
%       curves          (apply contrast map)                         amount:(-inf to +inf)
%       gammalight      (apply gamma correction map)                 amount:[0 to +inf)
%       gammadark       (apply inverse gamma correction map)         amount:[0 to +inf)
%       grain extract   (same as 'grainmerge' with FG inverted)
%       grain merge     (additive gain mapping)
%
%   Mesh Effects
%   --Arbitrary & Random
%       mesh            (apply arbitrary PWL transfer function)      amount:[0 1]
%       hard mesh       (apply arbitrary PWC transfer function)      amount:[0 1]
%       bomb            (random PWL transfer function)               amount:[1 to +inf)
%       bomb locked     (channel-locked bomb)                        amount:[1 to +inf)
%       hard bomb       (random PWC transfer function)               amount:[1 to +inf)
%   --Selected Presets
%       lcd             (FG is an LCD viewing angle map)             amount:[0 to +inf)
%       pelican                                                      amount:[0 to +inf)
%       muffle                                                       amount:[0 to +inf)
%       punch                                                        amount:[0 to +inf)
%       grapes                                                       amount:[0 to +inf)
%       ripe                                                         amount:[0 to +inf)
%
%   Modulo Effects
%       mod             (mod(amt*BG,FG))                             amount:[0 to +inf)
%       mod shift       (mod(amt*(BG+FG),1))                         amount:[0 to +inf)
%       mod divide      (mod(amt*(BG/FG),1))                         amount:[0 to +inf)
%       cmod            (continuized version of 'mod')               amount:[0 to +inf)
%       cmod shift      (continuized version of 'modshift')          amount:[0 to +inf)
%       cmod divide     (continuized version of 'moddivide')         amount:[0 to +inf)
%
%   Component
%       color           (shorthand for 'color hsly')
%       color hs{x}yc   (HS in HSL/HSV/HSI, luma-corrected, chroma-limited)
%       color hs{x}y    (HS in HSL/HSV/HSI, luma-corrected)
%       color hs{x}     (HS in HSL/HSV/HSI)
%       color hsyp      (HS in HSYp)
%       color lchab     (CH in CIELCHab)
%       color lchsr     (CH in SRLAB2 LCH)
%       hue             (H in CIELCHab)
%       saturation      (C in CIELCHab)
%       value           (max(R,G,B))
%       luma            (Rec601 or {Rec709})
%       lightness       (mean(min(R,G,B),max(R,G,B)))
%       intensity       (mean(R,G,B))
%       transfer inchan>outchan   (directly transfer any channel to another)
%       permute inchan>H     (rotate hue)                            amount:(-inf to +inf)
%       permute inchan>HS    (rotate hue and blend chroma)           amount:(-inf to +inf)
%
%   Special Modes
%       recolor lch {opts}  (recolor by histogram (LCHuv))           amount:[0 to +inf)
%       recolor hsly {opts} (recolor by histogram (HSL+Y))           amount:[0 to +inf)
%       blurmap {kernel}    (fake blurmap gimmick)                   amount:(1 to +inf)
%
%   COMMENTS ON BLEND MODES:
%       The 'lighten Y', 'darken Y', and some other component modes expect RGB input 
%       and will force expansion if fed single-channel images.
%
%       ABBREVIATIONS:
%       FG -- foreground image
%       BG -- background image
%       NRL -- neutral response locus
%       PWL -- piecewise linear
%       PWC -- piecewise constant
%
%       SYNONYMOUS MODES:
%       'equivalence' is referred to as 'phoenix' in several sources.
%       'average' is referred to as 'allanon' in Krita and EffectBank
%       'softlight' is referred to as 'pegtop light' by ImageMagick
%       'harmonic' is referred to as 'parallel' in Krita and EffectBank
%       'linearburn' is referred to as 'inverse subtract' in Krita
%       'sqrtdiff' is referred to as 'additive subtractive' in Krita and EffectBank
%       'maleki dodge' and burn are referred to as 'light' and 'shadow' in EffectBank and older versions of imblend
%       'fog lighten' and darken are referred to as 'bright' and 'dark' in EffectBank and older versions of imblend
%       'lighteneb' and 'darkeneb' were briefly referred to as 'dodge logarithmic' and 'burn logarithmic' in Krita
%       'gammadodge' is referred to as 'gamma illumination' or 'gamma bright' in Krita and other software.
%       'penumbra a1' and 'penumbra b1' are referred to as 'penumbra A' and 'penumbra B' in Krita
%           and are referred to as 'softdodge' and 'softburn' in older versions of imblend and elsewhere
%       'penumbra a2' and 'penumbra b2' are referred to as 'penumbra C' and 'penumbra D' in Krita
%           and are referred to as 'softdodge2' and 'softburn2' in older versions of imblend
%       'mod', 'modshift', and 'moddivide' are referred to as 'modulo', 'modulo shift', and 'divisive modulo' in Krita
%           continuized modes are 'modulo continuous', 'modulo shift continuous', and 'divisive modulo continuous'
%       Either name may be used.
%
%       COMBINED DIRECTIONAL MODES:
%       Several of the contrast-type modes can be thought of as bidirectional combinations of familiar unidirectional
%       mode pairs such as dodges and burns.  This relationship should help with understanding how and when to use  
%       them. The typical difference is a shift in the neutral color (to FG=0.5), and a doubling of dR/dFG.
%           'hard light' is a combination of 'screen' and 'multiply'
%           'vivid light' is a combination of 'colordodge' and 'colorburn'
%           'linear light' is a combination of 'lineardodge' and 'linearburn'
%           'easy light' is a combination of 'easydodge' and 'easyburn'
%           'pin light' is a combination of 'lightenrgb' and 'darkenrgb'
%       
%       SOFT LIGHT:
%       The assumed goal of these modes is to behave as a gamma adjustment function symmetric about FG=0.5. 
%       Roughly speaking, these are listed from fastest to most mathematically correct.
%       'softlight' is equivalent to ImageMagick, GIMP, and GEGL code.  Also known as 'pegtop light'.
%             This mode has gradient continuity, but poor symmetry.
%       'softlightps' is equivalent to all formulae found attributed to Photoshop (afaik). 
%       'softlightsvg' follows SVG 1.2 spec, and is nearly identical to 'softlightps'.
%             These modes have slight gradient discontinuity, but better symmetry.
%       'softlighteb' uses the faster of the two methods posed for EffectBank/Illusions
%             This mode has gradient continuity and only slight asymmetry, but it's ~2x as fast as 'eb2'.
%       'softlighteb2' is a parametric extension of the most accurate method posed for EffectBank
%             This mode has gradient continuity and symmetry for all parameter values.
%             In this mode, FG=[0 1] maps to gamma=[2^amount 1/(2^amount)].
%       See <a href="matlab: web(fullfile(fileparts(which('imblend')),'contour_plots.pdf'))">contour plot pdf</a> for graphical and tabular comparison of softlight modes.
%
%       OVERLAY & HARDLIGHT MODES:
%       For AMOUNT=1, these behave as per standard formulae. Otherwise, an alternative is used.
%       These are custom mesh modes which approximate iterated application of the named blend
%       in a fashion which is continuously scalable so as to simulate fractional iterates.
%       Consider the following examples using 'overlay'
%           For AMOUNT=0.7, results approximate a softlight blend
%           For AMOUNT=1, results are identical to standard methods
%           For AMOUNT=2, results approximate IMBLEND(FG,IMBLEND(FG,BG,1,'overlay'),1,'overlay')
%
%       FLAT LIGHT & VARIANTS:
%       The original 'flatlight' is a piecewise combination of 'penumbra a1' & 'penumbra b1'.  The effect is 
%       flat and somewhat opaque, tending to superimpose FG extrema.  The result is a middle ground between 
%       the behaviors and utility of 'vividlight' and 'pinlight'.  
%
%       'softflatlight' is a piecewise combination of 'penumbra a2' & 'penumbra b2'.  While otherwise very similar 
%       to 'flatlight', this trig-based variant trades the strictly neutral response at FG=0.5 for a more 
%       subtle response along the FG=BG diagonal.  Its lack of a simple neutral response makes it difficult to 
%       use in conventional manners. See <a href="matlab: web(fullfile(fileparts(which('imblend')),'contour_plots.pdf'))">contour plots</a>.
%
%       'softerflatlight' is a piecewise combination of 'penumbra a3' & 'penumbra b3'.  Much like 'softflatlight', 
%       the FG=0.5 neutral response is sacrificed to a greater degree. The result has a neutral response along
%       the FG=BG diagonal for AMOUNT=1. This neutral response location is suited for blending an image with an 
%       edited (e.g. blurmapped) copy of itself.  Of the three, this tends to be the softest or "flattest". 
%       For a unidirectional variant, see 'flatglow' and 'flatshadow'.
%
%       MEAN LIGHT & VARIANTS:
%       'meanlight' is a piecewise combination of 'penumbra a1' & 'penumbra b1'.  While the response for FG=0.5 is 
%       neutral, the response for FG=0 and FG=1 is mean(FG,BG).  The result is generally very flat and opaque.  
%
%       Like 'softerflatlight', 'softmeanlight' is a combination of 'penumbra a3' & 'penumbra b3', with the same 
%       tradeoff. The neutral response is about FG=BG instead of FG=0.5, and the result is softer than 'meanlight'.
%
%       MOON LIGHT MODES:
%       These are combinations of the 'moon' glow/shadow modes.  The result sweeps from BG to FG for a parameter 
%       range of [0 2], maintaining a neutral response along the FG=BG diagonal for all parameter values.  
%       Where the function response of 'moonlight2' is tangential to BG local to the NRL, 'moonlight' is tangential 
%       to mean(FG,BG) near the diagonal.  The result is a much more gradual inclusion of FG content than is 
%       typical for 'moonlight2' or remotely comparable modes such as 'pinlight'. 
%
%       Given the broader central NRL of 'moonlight2', this mode acts as a low-contrast softened version of 'pinlight' 
%       for intermediate parameters. Results are much less vivid than 'superlight'.     
%
%       STAR LIGHT:
%       This mode is very similar to 'moonlight', having similar behavior local to the FG=BG diagonal.  For most cases, 
%       'starlight' tends to be more aggressive than 'moonlight', as if a combination of the softness of 'average' with 
%       the vividness of 'softerflatlight'.  Depending on the application, the transposes of these combined hybrid 
%       modes may be more useful.
%
%       PIN LIGHT:
%       This mode combines lighten-only and darken-only thresholding to allow incorporation of FG
%       extrema into the BG image.  As AMOUNT is decreased, the thresholding becomes more exclusive.
%       Output equals BG for AMOUNT=0; output equals FG for AMOUNT=2. The NRL includes both FG=BG and FG=0.5.
%
%       SUPER LIGHT:
%       Piecewise union of functions whose level curves are superelliptic.  Allows transition between
%       behaviors of other blend modes. Useful in place of 'pin light' if a soft threshold is desired.
%           For AMOUNT=1, behavior matches 'linear light'
%           For AMOUNT=2, behavior is similar to 'hard light'
%           For AMOUNT>>2, behavior approaches 'pin light'
%
%       FOG LIGHTEN & DARKEN:
%       These are soft, partially-inverting bidirectional complements found originally in EffectBank/Illusions and 
%       later in Krita.  'Fog Lighten' is equivalent to doing an opacity blend using FG as its own opacity map 
%       (e.g. R = FG.*FG + BG.*(1-FG);).  While this may not be the raison d'etre, it does suggest applications
%       in which the minor FG gradient inversion is of no objectionable consequence.
%
%       QUADRATIC MODES:
%       'glow' and 'heat' are higher-ordered variants of 'colordodge' and 'colorburn'. Compared to the latter, they 
%       have subdued effect for default AMOUNT, though they are largely constant-valued and exhibit the same 
%       thresholding behavior.  While dodges and burns are unidirectional complementary pairs, the base quadratics 
%       are bidirectional complementary pairs, able to both lighten and darken over equal fractions of their domain. 
%       
%       The combination modes 'gleat' and 'helow' are symmetric modes derived from the prior.  'gleat' behaves similar 
%       to 'vividlight', whereas 'helow' is similar to 'overlay' but with the midtone contrast response inverted 
%       (see <a href="matlab: web(fullfile(fileparts(which('imblend')),'contour_plots.pdf'))">contour plots</a>).  'helow' and its transpose do not exhibit thresholding.  Unlike most contrast modes 
%       or true dodges/burns, none of the quadratics have a neutral FG color or any practically useful NRL. 
%
%       PENUMBRA VARIANTS:
%       Jens Gruschel's original formulae are a combination of 'colordodge' and inverse 'colorburn', referred to
%       as 'softdodge' and 'softburn'.  While the pair are complements like other dodge/burn modes, their extra 
%       symmetry makes them simple transposes as well.  These modes have no neutral response color, nor are they 
%       predominantly unidirectional.  Both modes lighten and darken over equal fractions of their domain.  This
%       makes it misleading to classify them as dodges/burns.  While they are more akin to bidirectional contrast 
%       modes, their extra symmetry and NRL location makes them a fairly distinct subcategory. The Krita devs were 
%       prudent to rename them, and I eventually adopted the 'penumbra' naming with some variation. 
%
%       The second variants are very similar to the original modes, with the same lack of a neutral response.
%       Similar to 'softflatlight', these are trig-based variants with only subtle slope differences. 
%       Mathematically, 'penumbra a2' is equivalent to 'arctan' with an inverted FG; 'penumbra b2' is the transpose.
%       These modes also have no neutral response along any linear locus.
%
%       The third variants are again very similar, but are designed specifically to have a neutral response along 
%       the FG=BG diagonal.  This results in an even softer or flatter appearance in typical use cases. 
%
%       MEAN-CENTERED CONTRAST MODES:
%       The modes 'scale add', 'scale mult', and 'contrast' are intended for uses similar to those of GIMP's
%       'grain merge' mode.  In normal operation, the FG content is treated as a mean-centered gain map for
%       the blend effect in question.  As an alternative to mean-centering, the center color may be specified
%       via AMOUNT in the form of [k cc], where k is the scaling factor and cc is the center color, which may
%       be either 1 or 3 elements;  i.e. [1 0.5] is equivalent to [1 0.5 0.5 0.5].  In this fashion, 'scale add'
%       and 'scale mult' effect adjustable additive and multiplicative gain mapping.  'contrast' acts as a 
%       levels tool, shifting the BG input white point or black point depending on FG value. This mode is
%       similar to a subtle application of 'vivid light', with its breakpoints controlled by the center color.
%       When cc=0 or 1, 'contrast' becomes equivalent to 'color dodge' or 'color burn'.  
%
%       CURVES:
%       This mode allows direct manipulation of BG contrast in a fashion similar to that of a curves tool.
%       This mode can take up to three parameters via AMOUNT.  A full specification is of the form [k os gp],
%       where k is a scaling factor, os is an offset (default 0), and gp is the input grey value (default 0.5).
%       The amount of curvature is modulated following C=(k*FG + os), and the midpoint of the curve is shifted 
%       by gp.  Setting k=0 allows scalar manipulation of contrast without the necessity for a solid FG fill.
%           When C>1, BG contrast is increased
%           When 0<C<1, BG contrast is decreased.
%           When C=0, BG = 0.5.
%           When C<0, BG is inverted, with contrast following abs(C)
%       With that in mind, AMOUNT=[0 1 0.5] is the null condition, and results in no change to the BG
%    
%       COLOR/POLY DODGE & BURN:
%       For the default parameter of 1, 'colordodge' and 'polydodge' are identical.  Both feature linear
%       meridians, but the limiting curve (the edge of the saturated region of the function) is an adjustable
%       linear function of FG for 'color' modes, and an adjustable-power monomial function of FG for 'poly' modes.
%       This means that 'poly' modes are less aggressive for parameter values >1, and tend to better retain
%       FG feature contrast for parameter values <1.  The linearity of 'color' modes may otherwise be preferred.
%
%       EASY DODGE & BURN:
%       These are modified power functions allowing scalable dodge/burn functionality without destroying highlight 
%       and shadow details.  While other methods are constant-valued for as much as half of their domain and tend 
%       to exhibit a thresholding behavior, the 'easy' modes are smooth over their entire domain.  Like 'lineardodge',
%       'easydodge' has improved influence over dark BG areas.  The result tends to be soft and less oversaturated, as if 
%       a compromise between 'colordodge' and 'screen'. These are good all-around tools for dodge/burn tasks where reduced 
%       contrast stretching is desired, or where a continuous gradient is desired.  The neutral colors are parameter-
%       dependent, occuring at FG=(1-AMOUNT) for 'easydodge', and FG=AMOUNT for 'easyburn'.  The original versions of 
%       these modes were slightly bidirectional to suit my own typical usage.  The parameter behavior has since been 
%       adjusted to conform to prevailing expectations of dodges/burns.  The original behavior can be achieved by 
%       setting AMOUNT=5/6 (~0.83).  If compatibility with the Krita implementation is desired, use AMOUNT=75/78 (~0.96).
%
%       GAMMA DODGE & BURN:
%       These are mathematically related to the 'easy' dodge/burn modes, and are smooth over their entire domain.  They 
%       can be considered a middle ground between the 'color' and 'easy' dodges and burns in terms of hardness, saturation, 
%       and influence over dark/light colors. Like the 'easy' modes, their neutral colors are parameter-dependent.  As pairs, 
%       'gammadodge' and 'gammaburn' conceptually address different goals than 'gammalight' and 'gammadark'.  For unity 
%       AMOUNT, 'gammaburn' and 'gammadark' are equivalent.
% 
%       SUAU DODGE & BURN:
%       These are unidirectional counterparts derived from 'softlighteb2', with correspondingly similar parameter behavior.  
%       Compared to other dodges/burns, the 'suau' modes are very subtle, with moderate response for even extreme FG values.
%       Unlike other pairs in this category, these modes are not complements. This property is a consequence of the parent
%       mode's atypical line symmetry about R=BG, where most bidirectional modes are point-symmetric.  Geometrically speaking, 
%       the relationship between this pair is the same as exists between 'easydodge' and 'gammaburn' or between 'colordodge' 
%       and 'multiply'. Complementary behavior is always available using the function transformation keys.  To replicate the 
%       steeper dR/dFG of the parent mode, use a parameter value of 2.  
%       
%       MALEKI DODGE & BURN:
%       Originally called 'light' and 'shadow' in EffectBank/Illusions, these modes are essentially dodges/burns roughly 
%       similar to the 'linear' modes but with a more aggressive response near their NRL and an eased response toward 
%       their extremities, exhibiting reduced thresholding behavior.  Steepness of the response eases as AMOUNT is reduced. 
%       For a parameter of 0.5, the response is equivalent to 'screen' and 'multiply'. As the parameter is reduced further 
%       toward zero, gradient inversion begins to occur, and the response becomes equivalent to 'fog lighten' and darken.
%       To reflect their properties as dodges/burns, I chose to rename them after their original author, Esthefan Maleki.
%
%       FLAT GLOW & SHADOW: 
%       The motivation for these modes was the need for a pair of unidirectional variants of 'softerflatlight'.  Since the 
%       penumbra modes from which 'flatlight' modes were derived are neither dodges/burns nor even unidirectional, 'flatglow' 
%       and 'flatshadow' were developed.  While these modes have the typical neutral response at FG=0 and FG=1 for dodge and 
%       burn, the NRL extends all the way to the FG=BG diagonal. For 'flatglow', the behavior transitions from BG to 
%       'lightenrgb' as AMOUNT is swept from 0 to 2, being a combination of 'penumbra a3' and BG for a parameter of 1.  
%       In this sense, this larger group of glow/shadow pairs are hybrid modes, bridging the gap between dodges/burns and the 
%       strict relational modes.  They are subtle and flat, useful for blending an image with a modified copy of itself.  
%       The primary neutral respnse loci are kept for all parameters.  Of the hybrid modes, the 'flat' and 'star' variants 
%       are the most vivid, though the 'flat' variants have the weakest response against extreme opposing BG colors.  Like 
%       'colordodge', 'flatglow' cannot lighten black BG regions (for AMOUNT=1), whereas the other hybrid glow modes can.
%       
%       MEAN GLOW & SHADOW: 
%       These are hybrid modes like 'flatglow' and shadow, sharing the same neutral response and similar utility.  
%       For 'meanglow', the behavior transitions from BG to 'lightenrgb' as AMOUNT is swept from 0 to 2, being 
%       a combination of 'average' and BG for a parameter of 1.  These are less vivid than the 'flat' modes.  
%       For AMOUNT from [1 2], it may be useful in cases where 'lightenrgb' is too destructive of dark BG content. 
%       The bidirectional counterpart to these modes is 'average'.
%
%       MOON GLOW & SHADOW: 
%       These are hybrid modes like those above, sharing the same NRL and similar utility.  Whereas 'meanglow' has  
%       piecewise-linear meridians, and 'flatglow' has convex meridians, 'moonglow' modes have piecewise-linear meridians 
%       joined by a quadratic ease curve.  The difference between the variants is the locus to which the ease curve is 
%       tangential.  Like 'moonlight', 'moonglow' is tangential to mean(FG,BG) local to the NRL for the default parameter.  
%      
%       Unlike 'moonglow', 'moonglow2' is tangential to R=BG.  This makes it the only hybrid mode with gradient  
%       continuity. Compared to the other hybrid modes, 'moonglow2' has reduced response near the FG=BG diagonal, which 
%       often makes it have weaker, more distally-localized effect when used in the same applications.
% 
%       STAR GLOW & SHADOW: 
%       These are hybrid modes like those above, sharing the same NRL and utility.  Like 'moonglow2', the behavior 
%       near the NRL is tangential to mean(FG,BG).  For images which are very close (e.g. an image and a blurred 
%       copy), the three modes 'meanglow', 'moonglow', and 'starglow' will appear nearly identical.  For colors 
%       distant from the NRL, 'meanglow' tends to be the most subtle and uniform, whereas 'starglow' tends to apply 
%       FG content in the most vivid manner. 
%
%       LIGHTEN & DARKEN RELATIONALS: 
%       The RGB modes are simple max/min relationals, much like GIMP's 'lighten only' and 'darken only'.
%       The hard edge of these RGB modes can be tempered by specifying easing via AMOUNT.  For AMOUNT=1, 
%       the operation is simple relational. Otherwise, AMOUNT<1 eases the transition with a smooth curve.  
%       For other means of easing, try one of the hybrid glow/shadow modes.
%       
%       'lighteny' and 'darkeny' are similar to Photoshop's 'lighter color' and 'darker color' modes. 
%       Here, the FG/BG pixel luma is evaluated and the pixels replaced as a whole instead of evaluating 
%       each channel. This results in a binary masking behavior when AMOUNT=1. Otherwise, the transition
%       between FG and BG is a linearized opacity blend.  
%
%       DISTANCE MODES:
%       The modes 'near' and 'far' locate regions in which FG and BG colors are within or beyond a weighted
%       euclidean distance.  Both modes accept an optional argument {layer} which may be 'fg' or 'bg'.
%           'near fg' will return only the FG content in the match region, filling with black elsewhere
%           'near bg' will return only the BG content in the match region, filling with black elsewhere
%           'near fga' will return only the FG content in the match region, performing alpha masking 
%           'near bga' will return only the BG content in the match region, performing alpha masking 
%           'near' merges matching FG content into BG
%       For RGB inputs, distance calculation is performed in YPbPr, with extra weighting on luma.
%       For distance specified by AMOUNT>=1, all colors are considered 'near'.
%
%       REPLACE & PRESERVE:
%       These incorporate simple masking behavior which allows the user to handle composition with
%       solid-color image matting.  For example, if AMOUNT=[0 0 0], 'replacebg' copies FG data  
%       to all black BG regions; 'replacefg' is the transpose.  Considering the same example, 
%       'preservebg' copies FG data to all non-black BG regions.  If AMOUNT is a scalar, it will be 
%       expanded as necessary. A second or fourth element may be included in the parameter to specify
%       the masking tolerance (default 0.01).  For example, [0 0.05] specifies black (expanded as necessary)
%       with a 5% mask tolerance.
%
%       SATURATE & DESATURATE:
%       Unlike the component mode 'saturation', these are relational modes operating on chroma in LCHuv, 
%       much like 'lightenrgb' operates on RGB channels. In these modes, AMOUNT modulates FG chroma.
%
%       MOST & LEAST SAT:
%       While 'saturate' maximizes the chroma channel while keeping H and L BG information untouched, 'mostsat' 
%       selects the color with the highest chroma.  Like 'lighteny', the pixels are replaced in whole.
%
%       AVERAGE, GEOMETRIC & HARMONIC MEAN:
%       Parameter adjustment allows the calculation of the weighted mean, where the relative weight is swept
%       from 100% BG to 100% FG over a parameter range of [0 2].  AGM and GHM modes are significantly slower.
%
%       COSINE INTERPOLATION:
%       'interpolate' does cosine interpolation from FG to BG.  The parameterization emulates iterative
%       behavior, replicating the behavior of Krita's 'interpolate 2' for AMOUNT=2, and generally
%       increasing contrast with each iteration.  Results rapidly approach 'hardmixps' as AMOUNT increases.
%       Conceptually, interpolate(FG,BG,2) = interpolate(interpolate(FG,BG,1),interpolate(FG,BG,1),1).
%       Fractional iterations are supported.
%
%       'hardint' is a quantized version of 'interpolate'.  AMOUNT controls the number of quantization levels.
%
%       DIFFERENCE MODES:
%       'difference' is the absolute difference between images.  Reducing AMOUNT lowers the white point, lending 
%       extra emphasis to results with subtle differences. The inverse is true for 'equivalence'.
%       
%       For a parameter range of [-1 1], 'sqrtdiff' shifts from the absolute difference of squares to the absolute
%       difference of square roots.  For a parameter of 0, 'sqrtdiff' is equivalent to 'difference'. 
%
%       'extremity' and 'negation' are equivalent to 'difference' and 'equivalence' with either image inverted.
%       The parameter behavior is not similar.
%
%       KRITA & EFFECTBANK/ILLUSIONS MODES:
%       'tint' and 'shade' are the transposes of 'malekidodge' and burn
%       'lighteneb' and 'darkeneb' are similar to a strong, transposed penumbra pair
%       'bleach' and 'stain' are the inverse of 'lineardodge' (addition), and 'linearburn'
%       'harmonic', aka 'parallel' is the harmonic mean; visually similar to 'geometric'
%       'arctan' is visually similar to 'penumbra a1' with an inverted FG
%       'hardoverlay' is a combination of 'multiply' and 'colordodge', more related to 'hardlight' than 'overlay'
%       'gammalight' and 'gammadark' allow gamma adjustment with AMOUNTxFG as a gamma map.
%
%       HARD MIX MODES:
%       'hardmixps' simply performs a thresholding along the (FG+BG)=1 diagonal.  For nonunity AMOUNT, the locus 
%           of this threshold shifts along the FG=BG diagonal.  In this manner, AMOUNT varies the brightness of 
%           the output, while the relative influence of FG versus BG remains equal.
%       'hardmixib' is a linearizing variant of 'hardmixps', and is equivalent for unity AMOUNT.  As AMOUNT is 
%           varied over [0 2], the function behavior blends from 'grainmerge' to 'meanlight'. In other words, 
%           AMOUNT varies the hardness of the thresholding, softening as AMOUNT deviates to either side of unity.
%       'hardmixkr' is a piecewise combination of 'colordodge' and 'colorburn', split along BG=0.5. The effect is
%           softer near FG extrema than a simple BG=0.5 thresholding would otherwise be. As AMOUNT is varied 
%           over [0 2], the function behavior nonlinearly blends from 'grainmerge' to a simple BG=0.5 thresholding.  
%           In other words, AMOUNT varies the hardness of the thresholding, becoming maximally hard at AMOUNT=2.
%
%       MESH MODES:
%       These modes accept AMOUNT in the form of a 2x2 or larger matrix whose elements represent
%       output intensity for input intensities from 0 to 1 (consider BG as horizontal axis, etc)
%       e.g [0 0.5; 0.5 1] is equivalent to 'average'; [0 0; 1 1] is the same as 'normal'
%       Compare to the included <a href="matlab: web(fullfile(fileparts(which('imblend')),'contour_plots.pdf'))">contour plots</a>; amount(1,1) is at the origin of BG and FG axes.
%       Values are assumed to be evenly spaced and are subject to interpolation (bilinear for 'mesh' 
%       and nearest-neighbor for 'hardmesh'). If AMOUNT is not set explicitly to a valid matrix, 
%       a warning will be dumped and a default used.
%
%       MESH MODE PRESETS:
%       'lcd' treats FG as a viewing angle map in the simulation of a low-quality TN LCD panel (see lcdemu()).
%       Other modes are ones I found attractive in certain specific cases.  As the silly names reflect, 
%       I don't really consider these to be formal modes.  I may adjust, rename, or delete them in time.
%       When using these presets, AMOUNT adjusts the contrast of the transfer function matrix.
%
%       BOMB MODES:
%       These are all mesh modes based on a random transfer function matrix of user-defined size.
%       For scalar AMOUNT, the tf matrix is of size (AMOUNT+1)x(AMOUNT+1).
%       When AMOUNT is a 2-element vector, the tf matrix is (AMOUNT(1)+1)x(AMOUNT(2)+1).
%       The 'bomb' mode applies a random piecewise-linear mesh blend
%       The 'bomblocked' mode is the same as 'bomb', but without channel-independence
%       The 'hardbomb' mode applies a random piecewise-constant mesh blend
%       Using the 'verbose' key with these modes will display the transformation matrix as a command string.
%       These can then be used with the mesh modes to reproduce a particular random blend.  
%       If you want to repeat a 'bomb' blend, but you don't have the transformation matrix, 
%       just load the script lost_bomb_recovery.m and follow the instructions.
%		
%       COLOR MODES: 
%       (BEST) 'lchab/sr' > 'hslyc' > 'hsly' (FAST)
%       'color hsxyc' modes are similar to 'color hsxy' modes, but the YPbPr transformation is chroma-limited.
%       This further reduces distortion of saturated colors, and improves white retention in HSV/HSI.
%       'color hsly', 'color hsvy' and 'color hsiy' are luma-corrected HS-swaps in the named models.
%       This reduces some brightness distortion problems with highly saturated overlay colors.
%       'color hsly', aka 'color' tends to give good results and is faster than the LCH or hslyc methods.
%       'color hsl' matches the legacy 'color' blend mode in GIMP
%       Uncorrected HSL/HSV/HSI modes are included only for sake of demonstration.
%       'color hsyp' attempts to provide good uniformity, at the cost of maximum chroma range.
%       'color lchsr' best approximates Photoshop behavior.
%       'color lchsr' is similar to the LCHab method, but with less blue-purple hue shift.
%
%       The 'hue' & 'saturation' modes are derived from LCHab instead of HSL as in GIMP.
%       If H or S modes are desired in HuSL, HSY, HSI or HSV, use 'transfer' instead.
%
%       TRANSFER MODES:
%       mode accepts channel strings based on RGBA, HuSLuv, HSY, HSYp, HSI, HSL, HSV, or CIELCHab models
%           'y', 'r', 'g', 'b', 'a'
%           'h_husl', 's_husl', 'l_husl'
%           'h_hsy', 's_hsy', 'y_hsy'
%           'h_hsyp', 's_hsyp', 'y_hsyp'
%           'h_hsi', 's_hsi', 'i_hsi'
%           'h_hsl', 's_hsl', 'l_hsl'
%           'h_hsv', 's_hsv', 'v_hsv'
%           'l_lch', 'c_lch', 'h_lch'
%       non-rgb symmetric channel transfers (e.g. V>V or Y>Y) are easier applied otherwise
%           (e.g. 'value' or 'luma' blend modes)
%  
%       PERMUTATION MODES:
%       modes can accept input channel strings 'h', 's', 'y', 'dh', 'ds', 'dy'
%       permutations actually occur on H and S in the HuSLuv model
%       color permutations (inchan>HS) combine hue rotation and chroma blending
%       chroma blending is maximized when abs(amount)==1
% 
%       RECOLOR MODES:
%       These modes use histogram matching to apply FG color information to the BG image without transferring any 
%       object content from the FG.  In other words, the BG is unsubtly forced to inherit a color "theme" from 
%       the FG.   See IMRECOLOR for details.  Operations can be done in LCHuv or in luma-corrected HSL (faster).  
%       Option substrings include the channel specification 'h','s', or 'hs'.  By default, these modes incorporate a blur 
%       operation in order to reduce speckling with some image combinations. AMOUNT may be a 2-element vector, where 
%       AMOUNT(1)*16 is the number of lightness bins, and where AMOUNT(2) is the despeckling blur size (default 10px).  
%       This blur can be disabled by setting blursize to 1px.   
%
%       BLURMAP MODES:
%       These are naive multipass opacity blended blur operations; no actual map analysis or segmentation is performed.  
%       The focal distance corresponds to FG=0; maximum blur occurs at FG=1.  A full spec for AMOUNT is [ks ga ka], where
%       ks is the max kernel size (default 20px), ga is ramp gamma (default 1), and ka is the kernel angle (only used for 
%       non-circular kernels, default 0). Kernel options are those supported by FKGEN. If no kernel is specified, 'gaussian' 
%       is used by default.  Kernels such as 'ring' may be better at distracting from the artifacts of the opacity blending 
%       if BG contains salient edge features that run parallel to the gradient of FG. See PSEUDOBLURMAP for more info. 
%
%   ============================= COMPOSITION MODES =============================
%   Porter-Duff 
%       src over                                                     camount:[0 to +inf)
%       src atop                                                     camount:[0 to +inf)
%       src in                                                       camount:[0 to +inf)
%       src out                                                      camount:[0 to +inf)
%       dst over                                                     camount:[0 to +inf)
%       dst atop                                                     camount:[0 to +inf)
%       dst in                                                       camount:[0 to +inf)
%       dst out                                                      camount:[0 to +inf)
%       xor                                                          camount:[0 to +inf)
%
%   Other
%       gimp                (default)
%       translucent     
%       dissolve {type}     (alpha dithering)                        camount:[0 1]
%       lindissolve {type}  (preserve linear alpha)                  camount:[0 1]
%   
%   COMMENTS ON COMPOSITION MODES:
%       Some of these modes (e.g. 'dst in', 'xor') don't really make much sense to use with
%       any blend mode other than 'normal'.  You're not restricted from doing it, though.
%       
%       'gimp' specifies the legacy approach used by GIMP prior to GEGL (default)
%       This is similar to SRC-OVER composition for 'normal' and a modified SRC-ATOP 
%       composition for other blends
%
%       The SVG 1.2 spec and GEGL follow a Porter-Duff SRC-OVER composition for all blends
%
%       PORTER-DUFF MODES:
%       If using these modes where hard-edged masking behavior is desired, specifying a nonunity CAMOUNT 
%       will invoke a thresholding operation on the FG alpha channel.  
%           CAMOUNT>1 sets all alpha <1 to 0
%           CAMOUNT in the interval (0,1) thresholds alpha at the specified value
%           CAMOUNT=0 will set all nonzero alpha to 1
%       Unlike other modes, using these on I/RGB inputs may force IA/RGBA output depending on the mode
%       and the value of specified OPACITY.  These are generally not useful cases.
%
%       TRANSLUCENT MODE:
%       This mode is based on an article by Søren Sandmann Pedersen, and uses a transmission-reflection
%       model to emulate the effect of a translucent material. Calculations are performed in linear RGB.
%
%       DISSOLVE MODES:   
%       These modes are essentially SRC-OVER composition after FG alpha is converted to a dithered
%       binary mask using one of the following methods:
%           'dissolve' applies a white noise thresholding dither (GIMP behavior)
%           'dissolve bn' applies a frequency-weighted (blue) noise dither
%           'dissolve ord' applies a 64-level ordered dither
%           'dissolve zf' applies a Zhou-Fang variable-coefficient E-D dither (best)
%       When using these modes, final mixdown opacity is linearly scaled with OPACITY as usual.
%       The masking density is controlled via CAMOUNT. The combination of dithering and linear opacity
%       makes the creation of texture or grain overlays very simple.
%
%       The 'lindissolve' modes offer the same methods, but the dithering is performed only on a uniform 
%       mask.  This leaves linear FG alpha intact, allowing for a different range of control. i.e.:
%           In 'dissolve', opacity is scalar (OPACITY) and density is a map (alpha*CAMOUNT)
%           In 'lindissolve', opacity is a map (alpha*OPACITY) and density is scalar (CAMOUNT)
%       When no FG alpha channel is present, 'dissolve' and 'lindissolve' are identical, with both
%       opacity and density controlled by scalars (OPACITY and CAMOUNT).
%
%   =====================================================================
%   EXAMPLES:
%      Do a simple multiply blend as would GIMP:
%          R=imblend(FG,BG,1,'multiply');
%
%      Specify SRC-OVER composition and use CAMOUNT for alpha thresholding:
%          R=imblend(FG,BG,1,'multiply','srcover',0.5);          
%
%   CLASS SUPPORT:
%       Accepts 'double','single','uint8','uint16','int16', and 'logical'
%       Return type is inherited from BG
%
% Webdocs: http://mimtdocs.rf.gd/manual/html/imblend.html
% See also: replacepixels, mergedown, imcompose

%   REFERENCES:
%	   https://www.ffmpeg.org/doxygen/2.4/vf__blend_8c_source.html
%	   http://dunnbypaul.net/blends/
%	   http://www.pegtop.net/delphi/articles/blendmodes/
%	   http://www.venture-ware.com/kevin/coding/lets-learn-math-photoshop-blend-modes/
%	   http://www.deepskycolors.com/archive/2010/04/21/formulas-for-Photoshop-blending-modes.html
%	   http://www.kineticsystem.org/?q=node/13
%	   http://www.simplefilter.de/en/basics/mixmods.html
%	   http://en.wikipedia.org/wiki/Blend_modes
%	   http://en.wikipedia.org/wiki/YUV
%	   https://en.wikipedia.org/wiki/Alpha_compositing
%	   http://www.adobe.com/content/dam/Adobe/en/devnet/acrobat/pdfs/PDF32000_2008.pdf
%	   https://dev.w3.org/SVG/modules/compositing/master/
%	   https://www.w3.org/TR/SVG11/filters.html#feBlendElement
%	   http://ssp.impulsetrain.com/porterduff.html
%	   http://ssp.impulsetrain.com/translucency.html
%	   GIMP 2.4 & 2.8.10 source
%	   Krita 3.1.4 & 4.2.9 source
%	   http://illusions.hu/effectwiki/doku.php?id=list_of_blendings (DEAD LINK, original author is Esthefan Maleki)
%	   https://mail.gnome.org/archives/gimp-developer-list/2012-July/msg00201.html
%	   https://yahvuu.files.wordpress.com/2009/09/table-contrast-2100b.png
%	   https://yahvuu.wordpress.com/2009/09/27/blendmodes1/

compkeys = {'gimp','translucent','srcover','srcatop','srcin','srcout','dstover','dstatop','dstin', ...
	'dstout','xor','dissolve','dissolvebn','dissolvezf','dissolveord','lindissolve','lindissolvebn','lindissolvezf','lindissolveord'};

amount = 1;
camount = 1;
compositionmode = 'gimp';
rec = 'rec601';
quiet = 0;
verbose = 0;
colormodel = 'rgb';
wclass = 'double'; 
invert = 0;
transpose = 0;
complement = 0;
linblend = false;
lincomp = false;

opacity = min(max(opacity,0),1);

compkeyset = 0;
for k = 1:1:length(varargin)
	if isnumeric(varargin{k})
		if compkeyset == 1
			camount = varargin{k}; 
		else
			amount = varargin{k};
		end
	elseif ischar(varargin{k})
		key = lower(varargin{k});
		key = key(key ~= ' ');
		switch key
			case compkeys
				compositionmode = key;
				compkeyset = 1;
			case {'rec601','rec709'}
				rec = key;
			case 'quiet'
				quiet = 1;
			case 'verbose'
				verbose = 1;
			case 'invert'
				invert = 1;
			case 'transpose'
				transpose = 1;
			case 'complement'
				complement = 1;
			case 'ypbpr'
				colormodel = 'ypbpr';
			case 'hsy'
				colormodel = 'hsy';
			case 'linear'
				linblend = true;
				lincomp = true;
			case 'linblend'
				linblend = true;
			case 'lincomp'
				lincomp = true;
			case 'double'
				wclass = 'double';
			case 'single'
				wclass = 'single';
			otherwise
				if ~quiet % only suppressed if quiet key comes first!
					fprintf('IMBLEND: Ignoring unknown key ''%s''\n',key)
				end 
		end
	end
end

% 'translucent' has always been done in linear rgb
if strcmp(compositionmode,'translucent')
	lincomp = true;
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check and modify datatypes %%%%%%%%%%%%%%%%%%%%%%%%%
% output type is inherited from BG
FG = imcast(FG,wclass);
[BG inclassBG] = imcast(BG,wclass);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check and modify dimensions %%%%%%%%%%%%%%%%%%%%%%%%%
% check if height & width match
sFG = size(FG);
sBG = size(BG);  
if any(sFG(1:2) ~= sBG(1:2)) 
	error('IMBLEND: images of mismatched dimension')
end

% check frame count and expand along dim 4 as necessary
if length(sFG) ~= 4 && length(sBG) ~= 4 % two single images
	nframes = 1;
else
	if length(sFG) ~= 4 % single FG, multiple BG
		FG = repmat(FG,[1 1 1 sBG(4)]);
	elseif length(sBG) ~= 4 % multiple FG, single BG
		BG = repmat(BG,[1 1 1 sFG(4)]); sBG = size(BG);
	elseif sFG(4) ~= sBG(4) % two unequal imagesets
		error('IMBLEND: imagesets of unequal length')
	end
	nframes = sBG(4);
end

% some blend modes expect RGB input; force expansion to avoid error bombing users
modestring = lower(blendmode(blendmode ~= ' '));
mustRGB = strismember(modestring,{'value','lightness','intensity','hue','saturation','luma','lighteny', ...
	'darkeny','color','colorlchab','colorlchsr','colorhsl','colorhsyp','saturate','desaturate','mostsat','leastsat'}) ...
	|| ~isempty([strmatch('transfer',modestring) strmatch('permute',modestring) strmatch('recolor',modestring)]) ...
	|| ~strcmp(colormodel,'rgb');

% get channel counts and alpha flags
% split alpha from color
[FG FGA] = splitalpha(FG);
[BG BGA] = splitalpha(BG);
FGhasalpha = ~isempty(FGA);
BGhasalpha = ~isempty(BGA);

% at this point, both FG and BG can only be 1 or 3 channel images with or without seperate alpha
% expand along dimension 3 where necessary
ccFG = size(FG,3);
ccBG = size(BG,3);
if ccFG < ccBG
	FG = repmat(FG,[1 1 3 1]);
elseif ccFG > ccBG
	BG = repmat(BG,[1 1 3 1]);
elseif mustRGB && all([ccFG == 1 ccBG == 1])
	FG = repmat(FG,[1 1 3 1]);
	BG = repmat(BG,[1 1 3 1]);
end

% if using modes which themselves can generate alpha content, make sure we have alpha
if strismember(modestring,{'nearfga','nearbga','farfga','farbga'}) && ~FGhasalpha && ~BGhasalpha
	BGhasalpha = 1; 
	BGA = ones([sBG(1:2) 1 nframes]);
end

% add a solid alpha channel where missing
if FGhasalpha == 0 && BGhasalpha == 1
	sFG = size(FG);
	FGA = ones([sFG(1:2) 1 size(FG,4)]);
elseif FGhasalpha == 1 && BGhasalpha == 0
	sBG = size(BG);
	BGA = ones([sBG(1:2) 1 size(BG,4)]);
end


% perform blend operations per frame %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if linblend
	FG = rgb2linear(FG);
	BG = rgb2linear(BG);
end

% these composition modes are not dependent on the results of any blend
% i.e. the [both] term is either 0 or BG, so just shunt straight to composition
noblendcompmodes = {'srcout','dstover','dstatop','dstin','dstout','xor'};

if strcmp(modestring,'normal') || strismember(compositionmode,noblendcompmodes)
	% if blend term is ignored, just jump straight to composition
	outpict = FG;
else
	 
	% these modes are the only ones which support non-scalar parameters
	if ~(strismember(modestring,{'mesh','hardmesh','replacecolor','excludecolor','replacebg','preservebg','replacefg','preservefg','curves','scaleadd', ...
			'scalemult','contrast','hardbomb'}) || ~isempty([strmatch('bomb',modestring) strmatch('recolor',modestring) strmatch('blurmap',modestring)])) && numel(amount) ~= 1  %#ok<*MATCH2>
		if ~quiet
			fprintf('IMBLEND: AMOUNT parameter must be scalar for ''%s'' mode.  Defaulting to 1\n',modestring)
		end
		amount = 1;
	end
	
	% preallocate as needed
	if nframes ~= 1
		outpict = zeros(size(BG)); 
	end
	
	% process each frame
	for f = 1:nframes
		if nframes == 1
			I = BG;
			M = FG;
		else
			I = BG(:,:,:,f);
			M = FG(:,:,:,f);
		end
		
		if transpose
			[I,M] = deal(M,I);
		end
		
		if complement
			I = 1-I;
			M = 1-M;
		end
		
		% apply CS transform
		switch colormodel
			case 'ypbpr'
				% convert to ych (with normalized H)
				M = rgb2lch(B,'ypbpr');
				M(:,:,3) = M(:,:,3)/360;
				I = rgb2lch(B,'ypbpr');
				I(:,:,3) = I(:,:,3)/360;
			case 'hsy'
				M = rgb2hsy(M,'normal');
				I = rgb2hsy(I,'normal');
				M(:,:,1) = M(:,:,1)/360; % normalize H
				I(:,:,1) = I(:,:,1)/360;				
		end

		% this is the core of imblend
		[R FGA(:,:,:,f) BGA(:,:,:,f)] = ibblender(M,I,modestring,amount,quiet,verbose,rec, ...
													FGA(:,:,:,f),BGA(:,:,:,f));

		% revert CS transform
		switch colormodel
			case 'ypbpr'
				R(:,:,3) = R(:,:,3)*360; % denormalize H
				R = lch2rgb(R,'ypbpr','truncatelch');
			case 'hsy'
				R(:,:,1) = R(:,:,1)*360; % denormalize H
				R = hsy2rgb(R,'normal');
		end
		
		if xor(complement,invert)
			R = 1-R;
		end		
		
		if nframes == 1
			outpict = R;
		else
			outpict(:,:,:,f) = R;
		end
	end
end
outpict = imclamp(outpict);

if linblend && ~lincomp
	outpict = linear2rgb(outpict);
	BG = linear2rgb(BG);
elseif ~linblend && lincomp
	outpict = rgb2linear(outpict);
	BG = rgb2linear(BG);
end

% handle alpha compositing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outpict = ibcomposite(outpict,FG,BG,FGA,BGA,FGhasalpha,BGhasalpha, ...
			compositionmode,modestring,opacity,camount,nframes);

if lincomp
	outpict = linear2rgb(outpict);
end

% handle output typecast %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outpict = imcast(outpict,inclassBG);


end %% END OF MAIN SCOPE

% bark bark bark
