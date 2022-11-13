//
//  mtldata.h
//  whatever
//
//  Created by user on 11/13/22.
//

#ifndef mtldata_h
#define mtldata_h

/**
 
 Key points: ambient is zero on every material, so map\_Ka is useless. It also is always the same as the diffuse texture.
 
 What's important is that we have a \_ddn and \_diff (or \_dif) texture for each material; most of these only differ in suffix as far as name is concerned,
 with few exceptions.
 
 There is a map\_Disp section which appears to not be supported by the fast\_obj lib, so what we do, here, instead of dealing with the overhead of going through
 
 all of this bogus, is just copy the texture name data into an array of C structures.

 0
 newmtl Material__25
 map_Kd textures/lion.tga
 map_Disp textures/lion_ddn.tga

 1
 newmtl Material__298
 map_Kd textures/background.tga
 map_Disp textures/background_ddn.tga

 2
 newmtl Material__47
 // nothing here

 3
 newmtl Material__57
 map_Kd textures/vase_plant.tga
 map_d textures/vase_plant_mask.tga
 
 4
 newmtl arch
 map_Kd textures/sponza_arch_diff.tga
 map_Disp textures/sponza_arch_ddn.tga

 5
 newmtl bricks
 map_Kd textures/spnza_bricks_a_diff.tga
 map_Disp textures/spnza_bricks_a_ddn.tga

 6
 newmtl ceiling
 map_Kd textures/sponza_ceiling_a_diff.tga
 map_Disp textures/sponza_ceiling_a_ddn.tga

 7
 newmtl chain
 map_Kd textures/chain_texture.tga
 map_d textures/chain_texture_mask.tga
 map_Disp textures/chain_texture_ddn.tga

 8
 newmtl column_a
 map_Kd textures/sponza_column_a_diff.tga
 map_Disp textures/sponza_column_a_ddn.tga

 9
 newmtl column_b
 map_Kd textures/sponza_column_b_diff.tga
 map_Disp textures/sponza_column_b_ddn.tga

 10
 newmtl column_c
 map_Kd textures/sponza_column_c_diff.tga
 map_Disp textures/sponza_column_c_ddn.tga

 11
 newmtl details
 map_Kd textures/sponza_details_diff.tga
 map_Disp textures/sponza_details_ddn.tga

 12
 newmtl fabric_a
 map_Kd textures/sponza_fabric_diff.tga
 map_Disp textures/sponza_fabric_ddn.tga

 13
 newmtl fabric_c
 map_Kd textures/sponza_curtain_diff.tga
 map_Disp textures/sponza_curtain_ddn.tga

 14
 newmtl fabric_d
 map_Kd textures/sponza_fabric_blue_diff.tga
 map_Disp textures/sponza_fabric_ddn.tga

 15
 newmtl fabric_e
 map_Kd textures/sponza_fabric_green_diff.tga
 map_Disp textures/sponza_fabric_ddn.tga

 16
 newmtl fabric_f
 map_Kd textures/sponza_curtain_green_diff.tga
 map_Disp textures/sponza_curtain_ddn.tga

 17
 newmtl fabric_g
 map_Kd textures/sponza_curtain_blue_diff.tga
 map_Disp textures/sponza_curtain_ddn.tga

 18
 newmtl flagpole
 map_Kd textures/sponza_flagpole_diff.tga
 map_Disp textures/sponza_flagpole_ddn.tga

 19
 newmtl floor
 map_Kd textures/sponza_floor_a_diff.tga
 map_Disp textures/sponza_floor_a_ddn.tga

 20
 newmtl leaf
 map_Kd textures/sponza_thorn_diff.tga
 map_Disp textures/sponza_thorn_ddn.tga

 21
 newmtl roof
 map_Kd textures/sponza_roof_diff.tga
 map_Ka textures/sponza_roof_ddn.tga

 22
 newmtl vase
 map_Kd textures/vase_dif.tga
 map_Disp textures/vase_ddn.tga

 23
 newmtl vase_hanging
 map_Kd textures/vase_hanging.tga
 map_Disp textures/vase_hanging_ddn.tga

 24
 newmtl vase_round
 map_Kd textures/vase_round.tga
 map_Disp textures/vase_round_ddn.tga
 
 */

#define NUM_MTL_TEXTURE_ENTRIES 25ul

struct MtlTextures
{
    const char* mtlName;
    const char* diffuse;
    const char* normal;
};

extern const struct MtlTextures MTL_TEXTURES[NUM_MTL_TEXTURE_ENTRIES];



#endif /* mtldata_h */
