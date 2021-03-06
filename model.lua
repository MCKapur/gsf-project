function createModel(nGPU)
  local model = nn.Sequential()

  -- Split along the time dimension
  model:add(nn.SplitTable(3))

  -- -- Apply convolutions to each time slice
  -- local c = nn.ConcatTable()
  -- c:add(nn.VolumetricConvolution(1, 96, 5, 5, 5))
  -- c:add(nn.ReLU(true))
  -- c:add(nn.VolumetricMaxPooling(5, 5, 5, 5, 5, 5))
  -- model:add(c)

  -- Build the recurrent layer
  local r = nn.GRU(61*73*61, 100)
  model:add(nn.Sequencer(r))

  -- Only keep the last time-step's output
  model:add(nn.SelectTable(-1))

  -- Classify
  model:add(nn.Linear(100, 2))
  model:add(nn.SoftMax())

  -- https://github.com/soumith/imagenet-multiGPU.torch/blob/master/models/alexnet.lua

  -- Make parallel-ready
  local model_single = model
  model = nn.DataParallelTable(1)
  for i=1, nGPU do
     cutorch.setDevice(i)
     model:add(model_single:clone():cuda(), i)
  end
  cutorch.setDevice(1)

  return model
end
