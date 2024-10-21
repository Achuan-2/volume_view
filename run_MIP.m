% 绘制三个方向的最大强度投影图
% 假设 imgStackDenoised 是你的 3D 图像数据，大小为 512x512x281
% 定义高斯滤波器的标准差
sigma = 1.0;

% 创建3D高斯滤波器
h = fspecial3('gaussian', [3 3 3], sigma);

% 对数据进行3D高斯滤波降噪
imgStackDenoised = imfilter(imgStack, h, 'replicate');

% 这里我们假设 imgStackDenoised 已经在工作空间中

% 计算沿 X 轴的最大强度投影
mipImageX = squeeze(max(imgStackDenoised, [], 1));
% 计算沿 Y 轴的最大强度投影
mipImageY = squeeze(max(imgStackDenoised, [], 2));
% 计算沿 Z 轴的最大强度投影
mipImageZ = squeeze(max(imgStackDenoised, [], 3));

% 计算每个像素的物理尺寸
pixelWidth = 285/512; % μm/pixel
pixelHeight = 5; % 每层的 step size 是 5 μm

% 计算目标尺寸
[imgWidth, imgHeight, imgZHeight] = size(imgStackDenoised);
targetWidth = imgWidth * pixelWidth; % μm
targetHeight = (imgZHeight - 1) * pixelHeight; % μm

% 计算缩放比例
scaleX = targetWidth / size(mipImageX, 2);
scaleY = targetHeight / size(mipImageX, 1);

% 调整图像尺寸
mipImageX_resized = imresize(mipImageX, [targetWidth, targetHeight]);
mipImageY_resized = imresize(mipImageY, [targetWidth, targetHeight]);
mipImageZ_resized = imresize(mipImageZ, [targetWidth, targetWidth]);

% 显示调整后的最大强度投影图像
% 设定figure的宽度和高度

% 自定义颜色映射
n = 256; % 定义颜色级数
greens = [linspace(0, 0, n)', linspace(0, 1, n)', linspace(0, 0, n)'];

% 创建一个新的figure窗口
f = figure();

% 绘制 X 轴投影
ax1 = subplot(1, 3, 1);
imagesc([0 targetWidth], [0 targetHeight], mipImageX_resized');
colormap(greens);
xlabel("Y (μm)");
ylabel("Z (μm)");
%title('MIP along X-axis');
axis xy;
daspect([1 1 1]);
ax1.TickDir = 'out';
ax1.XTick = 0:100:targetWidth;
ax1.YTick = 0:100:targetHeight;
box off;
set(gca, 'YDir', 'reverse');
exportgraphics(gca, "result_MIP along X-axis_origin.png", "Resolution", 600);
exportgraphics(gca, "result_MIP along X-axis_origin.pdf");
% 绘制 Y 轴投影
ax2 = subplot(1, 3, 2);
imagesc([0 targetWidth], [0 targetHeight], mipImageY_resized');
colormap(greens);
xlabel("X (μm)");
ylabel("Z (μm)");
title('MIP along Y-axis');
axis xy;
daspect([1 1 1]);
ax2.TickDir = 'out';
ax2.XTick = 0:100:targetWidth;
ax2.YTick = 0:100:targetHeight;
box off;
set(gca, 'YDir', 'reverse');
% 绘制 Z 轴投影
ax3 = subplot(1, 3, 3);
imagesc([0 targetWidth], [0 targetWidth], mipImageZ_resized');
colormap(greens);
xlabel("X (μm)");
ylabel("Y (μm)");
title('MIP along Z-axis');
axis xy;
daspect([1 1 1]);
ax3.TickDir = 'out';
ax3.XTick = 0:100:targetWidth;
ax3.YTick = 0:100:targetWidth;
box off;
set(gca, 'YDir', 'reverse');
