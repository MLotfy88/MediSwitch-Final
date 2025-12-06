import React from 'react';

interface MobileFrameProps {
  children: React.ReactNode;
}

const MobileFrame: React.FC<MobileFrameProps> = ({ children }) => {
  return (
    <div className="min-h-screen bg-muted flex items-center justify-center p-4">
      <div className="w-full max-w-[430px] min-h-[800px] bg-background rounded-[2.5rem] shadow-elevated overflow-hidden relative border-8 border-foreground/10">
        {/* Status Bar */}
        <div className="h-12 bg-surface flex items-center justify-between px-6 pt-2">
          <span className="text-xs font-medium text-foreground">9:41</span>
          <div className="flex items-center gap-1.5">
            <div className="flex gap-0.5">
              <div className="w-1 h-2.5 bg-foreground rounded-sm" />
              <div className="w-1 h-3 bg-foreground rounded-sm" />
              <div className="w-1 h-3.5 bg-foreground rounded-sm" />
              <div className="w-1 h-4 bg-foreground rounded-sm" />
            </div>
            <svg className="w-4 h-4 text-foreground" fill="currentColor" viewBox="0 0 24 24">
              <path d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.08 2.93 1 9zm8 8l3 3 3-3c-1.65-1.66-4.34-1.66-6 0zm-4-4l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.14 9.14 8.87 9.14 5 13z"/>
            </svg>
            <div className="flex items-center">
              <div className="w-6 h-3 border-2 border-foreground rounded-sm relative">
                <div className="absolute inset-0.5 bg-success rounded-sm" style={{ width: '70%' }} />
              </div>
            </div>
          </div>
        </div>
        
        {/* Content */}
        <div className="h-[calc(100%-3rem)] overflow-y-auto scrollbar-hide">
          {children}
        </div>
        
        {/* Home Indicator */}
        <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-foreground/30 rounded-full" />
      </div>
    </div>
  );
};

export default MobileFrame;
