# volume view

使用 matlab 绘制3d volume

## 开发背景

为了3d重建血管，折腾imagej、imaris、MATLAB的volshow、python的第三方库等等软件

使用上述方法进行3d重建时，发现几个痛点：
- 不方便设置axes的ticklabel
- 不方便多图统一角度
- 想画yz方向的最大强度投影
- 想保存pdf文件，而不是png图片
	
于是就想写代码自己实现，但是之前没接触过3d重建的代码，折腾了好久，最终在MATLAB fileexchange一个个查，最终发现vol3d 2这个库很好用，可以3d重建，但是也有几个问题
- 没有设置xyz的volpixelsize功能
- 如果自己调整xyz比例，就会发现层与层之间有黑线
- y轴方向是反的

于是我对vol3d v2的代码进行了修改，添加了volpixelsize的参数、linear interp插值、将图像方向调成与imaris 一致等功能。

## 用法

### 函数说明

`volume_view`函数用于在MATLAB中可视化三维体数据。它可以接受多种参数来定制显示效果，包括颜色数据、透明度、纹理、坐标数据等。

#### 函数签名

```matlab
function [model] = volume_view(varargin)
```

#### 参数说明

- `varargin`: 可变数量的输入参数。可以是以下键值对：
  - `'cdata'`: 三维或四维数组，表示体数据的颜色信息。
  - `'volsize'`: 向量，指定体数据的目标尺寸。
  - `'alpha'`: 三维数组，表示体数据的透明度信息。
  - `'parent'`: 图形对象的父对象，通常是一个坐标轴对象。
  - `'texture'`: 字符串，指定纹理类型，默认为 `'3D'`。
  - `'xdata'`, `'ydata'`, `'zdata'`: 向量，指定体数据在各个坐标轴上的范围。

#### 返回值

- `model`: 结构体，包含体数据的可视化模型及其相关属性。
## 示例

```matlab
[x, y, z] = meshgrid(-255:256, -255:256, -140:140);

% 定义哑铃参数
r_ball = 100;  % 球体半径
r_bar = 30;    % 连接杆半径
l_bar = 200;   % 连接杆长度

% 创建哑铃形状
dumbbell = ((x.^2 + y.^2 + (z-l_bar/2).^2 <= r_ball^2) | ...
            (x.^2 + y.^2 + (z+l_bar/2).^2 <= r_ball^2) | ...
            (x.^2 + y.^2 <= r_bar^2 & abs(z) <= l_bar/2));
 %%%%%%%%%%%%%%%%% 设置xyz代表的实际视野大小 %%%%%%%%%%%%%%%%%
volsize = [285,285,1400];

 %%%%%%%%%%%%%%%%% 绘图 %%%%%%%%%%%%%%%%%
 % 对数据进行3D高斯滤波降噪
sigma = 1.0;
h = fspecial3('gaussian', [3 3 3], sigma);
imgStackDenoised = imfilter(dumbbell, h, 'replicate');
% % 对数据进行3D中值降噪
%imgStackDenoised = medfilt3(imgStack, [3 3 3]);

 %%%%%%%%%%%%%%%%% 绘图 %%%%%%%%%%%%%%%%%
% 绘制数据
figure;
h = volume_view('cdata', double(imgStackDenoised), 'texture', '3D','volsize',volsize);
view(32,15); % 调整视角
% set(gca, 'color', [0, 0, 0]); % 设置背景颜色


% 自定义绿色颜色映射
greens = [linspace(0, 0, 256)', linspace(0, 1, 256)', linspace(0, 0, 256)'];
colormap(greens);

% 调整colormap范围，调整对比度
clim([0, 1]);
% 设置tickss
xticks(0:100:volsize(1));
yticks(0:100:volsize(2));
zticks(0:100:volsize(3));
xlabel('X (μm)');
ylabel('Y (μm)');
zlabel('Z (μm)');


```
![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/20241021144705-2024-10-21.png)

## 与vol3d v2的区别

本项目基于[vol3d v2](https://ww2.mathworks.cn/matlabcentral/fileexchange/22940-vol3d-v2)改进

原版的vol3d v2不能设置volsize，直接调用，绘制的比例不对，y和z的方向都是颠倒的

```matlab
% 绘制数据
figure;
h = vol3d('cdata', double(imgStack), 'texture', '3D','volsize',[285,285,1400]);
view(32,15);
axis tight;
set(gca, 'color', [0, 0, 0]); % 设置背景颜色

% 设置数据纵横比
daspect([512/285 512/285 281/1400]);

% 自定义绿色颜色映射
cmap = [linspace(0, 0, 256)', linspace(0, 1, 256)', linspace(0, 0, 256)'];
colormap(cmap);
clim([0, 35000]);


% 添加轴标签
xlabel('X (um)');
ylabel('Y (um)');
zlabel('Z (um)');
```
![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/20241021143725-2024-10-21.png)


绘图的时候尽管可以加代码修改，比如自己设置daspect，调整为正确的比例和ticklabel，但没有线性插值如果volszie过大会使得层与层之间会有明显的空隙。

```matlab
% 绘制数据
figure;
h = vol3d('cdata', double(imgStack), 'texture', '3D','volsize',[285,285,1400]);
view(32,15);
axis tight;
set(gca, 'ZDir', 'reverse');
set(gca, 'YDir', 'reverse');
set(gca, 'color', [0, 0, 0]); % 设置背景颜色

% 设置数据纵横比
daspect([512/285 512/285 281/1400]);

% 自定义绿色颜色映射
cmap = [linspace(0, 0, 256)', linspace(0, 1, 256)', linspace(0, 0, 256)'];
colormap(cmap);
clim([0, 35000]);


% 计算实际尺寸对应的数据索引
x_actual_range = 0:100:285;
y_actual_range = 0:100:285;
z_actual_range = 0:100:1400;

% 将实际尺寸转换为数据索引
x_ticks = x_actual_range * (512/285);
y_ticks = y_actual_range * (512/285);
z_ticks = z_actual_range * (281/1400);

% 设置刻度位置
xticks(x_ticks);
yticks(y_ticks);
zticks(z_ticks);

% 设置刻度标签为实际的物理尺寸
xticklabels(arrayfun(@(x) sprintf('%.0f', x), x_actual_range, 'UniformOutput', false));
yticklabels(arrayfun(@(y) sprintf('%.0f', y), y_actual_range, 'UniformOutput', false));
zticklabels(arrayfun(@(z) sprintf('%.0f', z), z_actual_range, 'UniformOutput', false));

% 添加轴标签
xlabel('X (um)');
ylabel('Y (um)');
zlabel('Z (um)');
```

![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/20241021143711-2024-10-21.png)


我对代码进行了修改

1. 支持设置xyz的volsize
2. 设置volsize会进行线性插值，减少黑线
3. 设置volsize绘图会正确显示xyz轴的ticklabel
4. 将原来y轴颠倒的图像调正，和在imaris viewer软件里显示的方向一致

![](https://fastly.jsdelivr.net/gh/Achuan-2/PicBed/assets/20241021143813-2024-10-21.png)


## 致谢

- [vol3d v2](https://ww2.mathworks.cn/matlabcentral/fileexchange/22940-vol3d-v2)
- [VOXview](https://ww2.mathworks.cn/matlabcentral/fileexchange/78745-voxview?s_tid=FX_rc1_behav)