local Themes = {}
Themes.Order = {"Pod_A", "Pod_B", "Pod_C", "Pod_D", "Pod_E"}
Themes.ByPod = {
 Pod_A = {Id="A", Name="Penjelajah Fajar", Template="DawnExplorer", Short="FAJAR", Accent=Color3.fromRGB(211,133,73), Dark=Color3.fromRGB(103,58,44), Cloth=Color3.fromRGB(235,216,177)},
 Pod_B = {Id="B", Name="Taman Mengapung", Template="FloatingGarden", Short="TAMAN", Accent=Color3.fromRGB(199,144,173), Dark=Color3.fromRGB(64,99,75), Cloth=Color3.fromRGB(219,183,193)},
 Pod_C = {Id="C", Name="Koi Langit", Template="SkyKoi", Short="KOI", Accent=Color3.fromRGB(229,147,70), Dark=Color3.fromRGB(86,66,53), Cloth=Color3.fromRGB(241,226,194)},
 Pod_D = {Id="D", Name="Pengelana Saturnus", Template="SaturnVoyager", Short="SATURNUS", Accent=Color3.fromRGB(157,161,223), Dark=Color3.fromRGB(42,50,86), Cloth=Color3.fromRGB(91,108,159)},
 Pod_E = {Id="E", Name="Lentera Istana", Template="PalaceLantern", Short="LENTERA", Accent=Color3.fromRGB(220,177,84), Dark=Color3.fromRGB(113,48,58), Cloth=Color3.fromRGB(204,135,116)},
}
function Themes.Get(podName)
 return Themes.ByPod[podName] or Themes.ByPod.Pod_A
end
return Themes
