% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

There are three main parts of the Ro4ActiveSrc:
1) Reorientation - estimates the OBS orientation through analysing the direct water signals
2) Relocation - estimates the on-bottom OBS position through analysing the direct water
3) Rotation - rotates the horizontal geophone data to their radial and transverse equivalents

Reorientation
-------------
- The algorithm used is adapted from Stachnik et al. (2012). Determination of New Zealand 
  Ocean Bottom Seismometer Orientation via Rayleigh-Wave Polarization. Seismological Research 
  Letters, Volume 83, Number 4.
- Only the part in the paper concerning P-wave Analysis was adapted to active source seismic
- The algorithm first search for the orientation (anti-clockwise from the x-component) with
  the highest radial/transverse absolute amplitude ratio of the direct water wave signals. 
  This is calculated for each of the picks. This is done through rotation using a 0-180 degree 
  search grid. Because of the 180 degree redundancy, the radial and vertical component was 
  cross-correlated to determine wether the optimized orientation should also be added 180 degree based
  on the polarity of the vertical component. The vertical componentIt is assumed to be positive 
  upward and the radial component positive from source to receiver. The positive y-axis is 
  assumed to be 90 degree anti-clockwise from the x-axis (right hand rule).
  Changes to left hand rule can be done by changing the channel assignment to each components.
- The x-referenced shot-receiver orientation of each shot is then subtracted from the shot-receiver 
  orientation to obtain the geo-reference orientation of the positive x-axis. Ideally, the resulting
  orientaions should converge. In reality, the values scatter due to poor signal-to-noise ratio and uncertainty in the true on-bottom OBS position. A mean orientation is calculated as a guide and the final 
  judgement on the best value lies on the person after reviewing the results. Note that values at the far offsets are usually more uniform and reliable.
  
Relocation
----------
- An on-bottom OBS position that is far off from what it actually was can result in very poor 
  performance in the Reorientation step. A routine is, therefore, developed to relocate the OBS 
  using both the direct wave traveltime and amplitude information. An on-the-line position is first
  obtained by optimizing the fit between calculated and modelled direct wave traveltime as shown in
  the contour plot. The off-the-line position is estimated by optimizing the fit between the source-receiver 
  orientation calculated from amplitude analyses and those modelled using the relocated position,
  assuming that the geo-reference x-axis orientation of the OBS is correct.
- Correlations between the observed and modelled source-receiver orientation is also calculated over
  the search grid of the offline position. 
- Hence, a position that has the minimum misfit in orientation and the maximum correlation is more likely 
  to be correct. Otherwise, there may be problem in the right-hand rule assumption and should be 
  changed.
- A re-analysis of the Reorientation step should follow this for a more accurate estimation of the 
  geo-referenced x-axis orientation. 
  
Rotation
--------
- Asumming all analyses have been completed and the correct OBS position and geo-referenced x-axis 
  orientation of the OBS have been obtained, the two horizontal components are to be rotated
  to their radial and transverse direction with respect to the source-reeceiver orientation
- And output text file records the rotation angles used and can be used to undo the results if needed.
- The rotation is done using the following formulae:
  Radial = X cos(OBS_az) + Y sin(OBS_az);
  Transverse = -X sin(OBS_az) + Y cos(OBS_az); where OBS_az is the rotation angle.
