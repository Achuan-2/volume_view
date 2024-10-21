function [model] = volume_view(varargin)
if nargin == 0
    disp("请输入参数");
    return
end

if isstruct(varargin{1})
    model = varargin{1};
    if length(varargin) > 1
       varargin = {varargin{2:end}};
    end
else
    model = localGetDefaultModel;
end

if length(varargin)>1
  for n = 1:2:length(varargin)
    switch(lower(varargin{n}))
        case 'cdata'
            model.cdata = varargin{n+1};
        case 'parent'
            model.parent = varargin{n+1};
        case 'texture'
            model.texture = varargin{n+1};
        case 'alpha'
            model.alpha = varargin{n+1};
        case 'xdata'
            model.xdata = varargin{n+1}([1 end]);
        case 'ydata'
            model.ydata = varargin{n+1}([1 end]);
        case 'zdata'
            model.zdata = varargin{n+1}([1 end]);
        case 'volsize'
            model.volsize = varargin{n+1};
    end
  end
end

if isempty(model.parent)
    model.parent = gca;
end

[model] = local_draw(model);

%------------------------------------------%
function [model] = localGetDefaultModel

model.cdata = [];
model.alpha = [];
model.xdata = [];
model.ydata = [];
model.zdata = [];
model.volsize = [];
model.parent = [];
model.handles = [];
model.texture = '3D';
tag = tempname;
model.tag = ['vol3d_' tag(end-11:end)];

%------------------------------------------%
function [model,ax] = local_draw(model)

cdata = model.cdata; 
siz = size(cdata);

% 定义 [x,y,z]data
if isempty(model.xdata)
    model.xdata = [0 siz(2)];
end
if isempty(model.ydata)
    model.ydata = [0 siz(1)];
end
if isempty(model.zdata)
    model.zdata = [0 siz(3)];
end

% 如果指定了 volsize，则对 cdata 和 alpha 进行插值
if ~isempty(model.volsize)
    volsize = model.volsize;
    if length(volsize) == 1
        volsize = [volsize, volsize, volsize];
    elseif length(volsize) ~= 3
        error('volsize 必须是长度为 1 或 3 的向量');
    end
    old_siz = siz(1:3);
    new_siz = volsize;

    % 对 cdata 进行插值
    [X,Y,Z] = ndgrid(1:old_siz(1), 1:old_siz(2), 1:old_siz(3));
    [Xq,Yq,Zq] = ndgrid(linspace(1,old_siz(1),new_siz(1)), ...
                        linspace(1,old_siz(2),new_siz(2)), ...
                        linspace(1,old_siz(3),new_siz(3)));
    if ndims(cdata) == 4
        % 对于 4D cdata（如 RGB）
        cdata_new = zeros([new_siz, siz(4)], class(cdata));
        for k = 1:siz(4)
            cdata_new(:,:,:,k) = interpn(X, Y, Z, cdata(:,:,:,k), Xq, Yq, Zq, 'linear');
        end
        cdata = cdata_new;
    else
        F = griddedInterpolant({1:old_siz(1), 1:old_siz(2), 1:old_siz(3)}, cdata);
        cdata = F({linspace(1,old_siz(1),new_siz(1)), linspace(1,old_siz(2),new_siz(2)), linspace(1,old_siz(3),new_siz(3))});

    end
    siz = size(cdata);


    % 对 alpha 进行插值
    if ~isempty(model.alpha)
        alpha = model.alpha;
        if isequal(size(alpha), old_siz)
            alpha = interpn(X, Y, Z, alpha, Xq, Yq, Zq, 'linear');
        else
            error('alpha 的大小与 cdata 不匹配');
        end
        model.alpha = alpha; 
    end
    % 在调整了 cdata 和 siz 之后，定义 [x,y,z]data
    if isempty(model.xdata)
        model.xdata = [0 siz(2)];
    else
        % 如果需要保持物理尺寸不变，可以根据比例调整 xdata
        scale_x = siz(2) / old_siz(2);
        model.xdata = model.xdata * scale_x;
    end
    if isempty(model.ydata)
        model.ydata = [0 siz(1)];
    else
        scale_y = siz(1) / old_siz(1);
        model.ydata = model.ydata * scale_y;
    end
    if isempty(model.zdata)
        model.zdata = [0 siz(3)];
    else
        scale_z = siz(3) / old_siz(3);
        model.zdata = model.zdata * scale_z;
    end

end

try
   delete(model.handles);
catch
end

ax = model.parent;
cam_dir = camtarget(ax) - campos(ax);
[~,ind] = max(abs(cam_dir));
axis tight;
ax.ZDir = 'reverse';
ax.YDir = 'reverse';
ax.Color = [0,0,0];
daspect([1 1 1]);
opts = {'Parent',ax,'cdatamapping',[],'alphadatamapping',[],'facecolor','texturemap','edgealpha',0,'facealpha','texturemap','tag',model.tag};

if ndims(cdata) > 3
    opts{4} = 'direct';
else
    cdata = double(cdata);
    opts{4} = 'scaled';
end

if isempty(model.alpha)
    alpha = cdata;
    if ndims(model.cdata) > 3
        alpha = sqrt(sum(double(alpha).^2, 4));
        alpha = alpha - min(alpha(:));
        alpha = 1 - alpha / max(alpha(:));
    end
    opts{6} = 'scaled';
else
    alpha = model.alpha;
    if ~isequal(siz(1:3), size(alpha))
        error('alphamatte 的大小不正确');
    end
    opts{6} = 'none';
end

h = findobj(ax,'type','surface','tag',model.tag);
for n = 1:length(h)
  try
     delete(h(n));
  catch
  end
end

is3DTexture = strcmpi(model.texture,'3D');
handle_ind = 1;

% 创建 z 切片
if(ind==3 || is3DTexture )    
  x = [model.xdata(1), model.xdata(2); model.xdata(1), model.xdata(2)];
  y = [model.ydata(1), model.ydata(1); model.ydata(2), model.ydata(2)];
  z_slices = linspace(model.zdata(1), model.zdata(2), siz(3)+1);
  for n = 1:siz(3)
    cslice = squeeze(cdata(:,:,n,:));
    aslice = double(squeeze(alpha(:,:,n)));
    z = [z_slices(n), z_slices(n); z_slices(n), z_slices(n)];
    h(handle_ind) = surface(x,y,z,cslice,'alphadata',aslice,opts{:});
    handle_ind = handle_ind + 1;
  end
end

% 创建 x 切片
if (ind==1 || is3DTexture ) 
  y = [model.ydata(1), model.ydata(1); model.ydata(2), model.ydata(2)];
  z = [model.zdata(1), model.zdata(2); model.zdata(1), model.zdata(2)];
  x_slices = linspace(model.xdata(1), model.xdata(2), siz(2)+1);
  for n = 1:siz(2)
    cslice = squeeze(cdata(:,n,:,:));
    aslice = double(squeeze(alpha(:,n,:)));
    x = [x_slices(n), x_slices(n); x_slices(n), x_slices(n)];
    h(handle_ind) = surface(x,y,z,cslice,'alphadata',aslice,opts{:});
    handle_ind = handle_ind + 1;
  end
end

% 创建 y 切片
if (ind==2 || is3DTexture)
  x = [model.xdata(1), model.xdata(1); model.xdata(2), model.xdata(2)];
  z = [model.zdata(1), model.zdata(2); model.zdata(1), model.zdata(2)];
  y_slices = linspace(model.ydata(1), model.ydata(2), siz(1)+1);
  for n = 1:siz(1)
    cslice = squeeze(cdata(n,:,:,:));
    aslice = double(squeeze(alpha(n,:,:)));
    y = [y_slices(n), y_slices(n); y_slices(n), y_slices(n)];
    h(handle_ind) = surface(x,y,z,cslice,'alphadata',aslice,opts{:});
    handle_ind = handle_ind + 1;
  end
end

model.handles = h;

