param([string]$SrcDir, [string]$OutDir, [int]$Max = 380)
# Turn background-removed dog photos into stickers with a white border.
# PNGs: use their transparency. JPGs: the removed background is pure white, so flood-fill
# near-white from the image edges to find it.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class Sticker {
  public static Bitmap Make(Bitmap src, bool useAlpha, int tol) {
    int w = src.Width, h = src.Height;
    Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, w, h);
    BitmapData d = bmp.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int[] px = new int[w*h]; Marshal.Copy(d.Scan0, px, 0, px.Length); bmp.UnlockBits(d);
    bool[] fg = new bool[w*h];
    if (useAlpha) {
      for (int i=0;i<px.Length;i++) fg[i] = ((px[i]>>24)&255) > 60;
    } else {
      bool[] bg = new bool[w*h]; Queue<int> q = new Queue<int>();
      for (int x=0;x<w;x++){ q.Enqueue(x); q.Enqueue((h-1)*w+x); }
      for (int y=0;y<h;y++){ q.Enqueue(y*w); q.Enqueue(y*w+w-1); }
      int lim = 255 - tol;
      while (q.Count>0) { int i=q.Dequeue(); if (bg[i]) continue; int c=px[i];
        if (((c>>16)&255)<lim || ((c>>8)&255)<lim || (c&255)<lim) continue;
        bg[i]=true; int x=i%w, y=i/w;
        if (x>0) q.Enqueue(i-1); if (x<w-1) q.Enqueue(i+1); if (y>0) q.Enqueue(i-w); if (y<h-1) q.Enqueue(i+w); }
      for (int i=0;i<px.Length;i++) fg[i] = !bg[i];
    }
    // drop tiny specks (keep pieces at least 0.4% of the subject)
    int[] lab = new int[w*h]; List<int> sizes = new List<int>(); sizes.Add(0); int total=0;
    Queue<int> qq = new Queue<int>();
    for (int s=0;s<w*h;s++){ if(!fg[s]||lab[s]!=0) continue; int id=sizes.Count; int n=0; lab[s]=id; qq.Enqueue(s);
      while(qq.Count>0){ int i=qq.Dequeue(); n++; int x=i%w,y=i/w;
        if(x>0&&fg[i-1]&&lab[i-1]==0){lab[i-1]=id;qq.Enqueue(i-1);} if(x<w-1&&fg[i+1]&&lab[i+1]==0){lab[i+1]=id;qq.Enqueue(i+1);}
        if(y>0&&fg[i-w]&&lab[i-w]==0){lab[i-w]=id;qq.Enqueue(i-w);} if(y<h-1&&fg[i+w]&&lab[i+w]==0){lab[i+w]=id;qq.Enqueue(i+w);} }
      sizes.Add(n); total+=n; }
    int minKeep = Math.Max(20, total/250);
    int x0=w,y0=h,x1=-1,y1=-1;
    for (int i=0;i<w*h;i++){ if(fg[i] && sizes[lab[i]]<minKeep) fg[i]=false;
      if(fg[i]){int x=i%w,y=i/w; if(x<x0)x0=x; if(x>x1)x1=x; if(y<y0)y0=y; if(y>y1)y1=y;} }
    if (x1<0) return null;
    int R = Math.Max(6, (int)(0.04*Math.Max(x1-x0, y1-y0)));
    int pad = R+3;
    int cw = x1-x0+1+2*pad, ch = y1-y0+1+2*pad;
    bool[] m = new bool[cw*ch]; int[] col = new int[cw*ch];
    for (int y=y0;y<=y1;y++) for (int x=x0;x<=x1;x++){ int i=y*w+x, j=(y-y0+pad)*cw+(x-x0+pad); m[j]=fg[i]; col[j]=px[i]; }
    // grow the silhouette by R (alternating square and cross steps gives a rounded outline)
    bool[] grown = (bool[])m.Clone();
    for (int r=0;r<R;r++){ bool[] nx=(bool[])grown.Clone(); bool sq=(r%2==0);
      for (int y=1;y<ch-1;y++) for (int x=1;x<cw-1;x++){ int j=y*cw+x; if(grown[j]) continue;
        bool on = grown[j-1]||grown[j+1]||grown[j-cw]||grown[j+cw];
        if(!on && sq) on = grown[j-cw-1]||grown[j-cw+1]||grown[j+cw-1]||grown[j+cw+1];
        if(on) nx[j]=true; }
      grown=nx; }
    int[] outPx = new int[cw*ch];
    unchecked {
      int white = (int)0xFFFFFFFF;
      for (int j=0;j<cw*ch;j++){
        if (m[j]) outPx[j] = col[j] | (255<<24);
        else if (grown[j]) outPx[j] = white;
        else outPx[j] = 0;
      }
      // soften the outer edge
      for (int y=1;y<ch-1;y++) for (int x=1;x<cw-1;x++){ int j=y*cw+x;
        if (grown[j] && (!grown[j-1]||!grown[j+1]||!grown[j-cw]||!grown[j+cw])) outPx[j] = (outPx[j]&0x00FFFFFF)|(150<<24); }
    }
    Bitmap o = new Bitmap(cw, ch, PixelFormat.Format32bppArgb);
    BitmapData od = o.LockBits(new Rectangle(0,0,cw,ch), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    Marshal.Copy(outPx, 0, od.Scan0, outPx.Length); o.UnlockBits(od);
    return o;
  }
}
"@
New-Item -ItemType Directory -Force $OutDir | Out-Null
$files = Get-ChildItem -LiteralPath $SrcDir -File | Where-Object { $_.Extension -match '^\.(png|jpe?g)$' } | Sort-Object Name
$n = 0; $made = @()
foreach ($f in $files) {
  $im = New-Object System.Drawing.Bitmap $f.FullName
  if ($im.PropertyIdList -contains 0x0112) { switch ($im.GetPropertyItem(0x0112).Value[0]) { 3 {$im.RotateFlip('Rotate180FlipNone')} 6 {$im.RotateFlip('Rotate90FlipNone')} 8 {$im.RotateFlip('Rotate270FlipNone')} } }
  # work at a modest size: scale so the longer side is about $Max
  $sc = [Math]::Min(1.0, $Max / [Math]::Max($im.Width, $im.Height))
  $w = [int]($im.Width * $sc); $h = [int]($im.Height * $sc)
  $small = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($small); $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
  $g.DrawImage($im, 0, 0, $w, $h); $g.Dispose()
  $hasAlpha = $f.Extension -match 'png' -and ($im.PixelFormat -eq [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $st = [Sticker]::Make($small, $hasAlpha, 22)
  $im.Dispose(); $small.Dispose()
  if ($st -eq $null) { "skipped (empty): $($f.Name)"; continue }
  $n++; $name = "dog-{0:D2}.png" -f $n
  $st.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
  $made += "$name <- $($f.Name) ($($st.Width)x$($st.Height))"; $st.Dispose()
}
$made
# contact sheet on mid-grey to check the cut edges
$out = Get-ChildItem -LiteralPath $OutDir -Filter 'dog-*.png' | Sort-Object Name
$cols = 10; $cell = 110; $rows = [Math]::Ceiling($out.Count / $cols)
$cs = New-Object System.Drawing.Bitmap ($cols*$cell), ($rows*$cell); $g = [System.Drawing.Graphics]::FromImage($cs)
$g.Clear([System.Drawing.Color]::FromArgb(110,110,110)); $g.InterpolationMode = 'HighQualityBicubic'
$i = 0; foreach ($o in $out) { $im = [System.Drawing.Image]::FromFile($o.FullName)
  $sc = [Math]::Min(($cell-8)/$im.Width, ($cell-8)/$im.Height); $w = [int]($im.Width*$sc); $h = [int]($im.Height*$sc)
  $g.DrawImage($im, ($i%$cols)*$cell + [int](($cell-$w)/2), [Math]::Floor($i/$cols)*$cell + [int](($cell-$h)/2), $w, $h); $im.Dispose(); $i++ }
$g.Dispose(); $cs.Save((Join-Path $OutDir 'check.png'), [System.Drawing.Imaging.ImageFormat]::Png)
"total stickers: $($out.Count); folder size: " + [int](($out | Measure-Object Length -Sum).Sum / 1KB) + " KB"
