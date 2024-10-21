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
