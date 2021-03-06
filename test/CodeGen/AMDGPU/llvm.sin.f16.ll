; RUN: llc -march=amdgcn -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=SI %s
; RUN: llc -march=amdgcn -mcpu=fiji -mattr=-flat-for-global -verify-machineinstrs < %s | FileCheck -check-prefix=GCN -check-prefix=VI %s

declare half @llvm.sin.f16(half %a)
declare <2 x half> @llvm.sin.v2f16(<2 x half> %a)

; GCN-LABEL: {{^}}sin_f16
; GCN: buffer_load_ushort v[[A_F16:[0-9]+]]
; GCN: v_cvt_f32_f16_e32 v[[A_F32:[0-9]+]], v[[A_F16]]
; GCN: v_mul_f32_e32 v[[M_F32:[0-9]+]], {{0.15915494|0x3e22f983}}, v[[A_F32]]
; GCN: v_fract_f32_e32 v[[F_F32:[0-9]+]], v[[M_F32]]
; GCN: v_sin_f32_e32 v[[R_F32:[0-9]+]], v[[F_F32]]
; GCN: v_cvt_f16_f32_e32 v[[R_F16:[0-9]+]], v[[R_F32]]
; GCN: buffer_store_short v[[R_F16]]
; GCN: s_endpgm
define void @sin_f16(
    half addrspace(1)* %r,
    half addrspace(1)* %a) {
entry:
  %a.val = load half, half addrspace(1)* %a
  %r.val = call half @llvm.sin.f16(half %a.val)
  store half %r.val, half addrspace(1)* %r
  ret void
}

; GCN-LABEL: {{^}}sin_v2f16
; GCN: buffer_load_dword v[[A_V2_F16:[0-9]+]]
; SI:  v_mov_b32_e32 v[[HALF_PIE:[0-9]+]], 0x3e22f983{{$}}
; SI: v_lshrrev_b32_e32 v[[A_F16_1:[0-9]+]], 16, v[[A_V2_F16]]
; SI-DAG: v_cvt_f32_f16_e32 v[[A_F32_1:[0-9]+]], v[[A_F16_1]]
; SI-DAG: v_cvt_f32_f16_e32 v[[A_F32_0:[0-9]+]], v[[A_V2_F16]]


; VI: v_cvt_f32_f16_e32 v[[A_F32_0:[0-9]+]], v[[A_V2_F16]]
; VI: v_lshrrev_b32_e32 v[[A_F16_1:[0-9]+]], 16, v[[A_V2_F16]]
; VI: v_cvt_f32_f16_e32 v[[A_F32_1:[0-9]+]], v[[A_F16_1]]


; SI-DAG:  v_mul_f32_e32 v[[M_F32_0:[0-9]+]], v[[HALF_PIE]], v[[A_F32_0]]
; VI-DAG:  v_mul_f32_e32 v[[M_F32_0:[0-9]+]], 0.15915494, v[[A_F32_0]]
; GCN-DAG: v_fract_f32_e32 v[[F_F32_0:[0-9]+]], v[[M_F32_0]]

; SI-DAG:  v_mul_f32_e32 v[[M_F32_1:[0-9]+]], v[[HALF_PIE]], v[[A_F32_1]]
; VI-DAG:  v_mul_f32_e32 v[[M_F32_1:[0-9]+]], 0.15915494, v[[A_F32_1]]
; GCN-DAG: v_fract_f32_e32 v[[F_F32_1:[0-9]+]], v[[M_F32_1]]

; GCN-DAG: v_sin_f32_e32 v[[R_F32_0:[0-9]+]], v[[F_F32_0]]
; GCN-DAG: v_sin_f32_e32 v[[R_F32_1:[0-9]+]], v[[F_F32_1]]
; GCN-DAG: v_cvt_f16_f32_e32 v[[R_F16_0:[0-9]+]], v[[R_F32_0]]
; GCN-DAG: v_cvt_f16_f32_e32 v[[R_F16_1:[0-9]+]], v[[R_F32_1]]
; GCN: v_lshlrev_b32_e32 v[[R_F16_HI:[0-9]+]], 16, v[[R_F16_1]]
; GCN: v_or_b32_e32 v[[R_V2_F16:[0-9]+]], v[[R_F16_HI]], v[[R_F16_0]]
; GCN: buffer_store_dword v[[R_V2_F16]]
; GCN: s_endpgm
define void @sin_v2f16(
    <2 x half> addrspace(1)* %r,
    <2 x half> addrspace(1)* %a) {
entry:
  %a.val = load <2 x half>, <2 x half> addrspace(1)* %a
  %r.val = call <2 x half> @llvm.sin.v2f16(<2 x half> %a.val)
  store <2 x half> %r.val, <2 x half> addrspace(1)* %r
  ret void
}
