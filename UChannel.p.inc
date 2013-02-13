{Photoshop version 1.0.1, file: UChannel.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION DoSetChannelCommand
		(view: TImageView; channel: INTEGER): TCommand; EXTERNAL;

FUNCTION DoNewChannel (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSplitChannels (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoMergeChannels (view: TImageView): TCommand; EXTERNAL;
