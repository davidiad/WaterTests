## WaterTests
This project is a test to create water with the Unity 5 Standard shader and gerstner waves. Combining the use of the Gerstner waves from the Water4 shader that comes with Unity, with the Standard shader. (The Water4 shader does not react to lights). 

The ultimate goals are:  
1. to allow meshes of varying shape (representing a waterfall for instance), that can accept a map controlling how much and where Gerstner wave intensity is applied
2. to be usable with a Level of Detail group, for smooth water with a reasonable poly count
3. to be tileable, so that only a small section of mesh at a time needs the highest level of detail
4. to accept a flow map for bump distortion that flows with a water channel
