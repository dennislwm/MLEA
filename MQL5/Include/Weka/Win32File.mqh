//+------------------------------------------------------------------+
//|                                                UnlimitedFile.mqh |
//|                                                         Zephyrrr |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zephyrrr"
#property link      "http://www.mql5.com"

#define INVALID_HANDLE_VALUE -1
#define GENERIC_READ  0x80000000
#define GENERIC_WRITE  0x40000000
#define CREATE_NEW 0x01
#define CREATE_ALWAYS 0x02
#define OPEN_EXISTING  0x03
#define FILE_ATTRIBUTE_NORMAL 0x80
#define WIN32_FILE_SHARE_READ 0x01
#define WIN32_FILE_SHARE_WRITE 0x02

#import "kernel32.dll"
int CreateFileW(string name,int desiredAccess,int SharedMode,int security,int creation,int flags,int templateFile);
int WriteFile(int fileHandle,short &buffer[],int bytes,int &numOfBytes,int overlapped);
int WriteFile(int fileHandle,char &buffer[],int bytes,int &numOfBytes,int overlapped);
//int WriteFile(int fileHandle,MqlTick &outgoing,int bytes,int &numOfBytes,int overlapped);
int WriteFile(int fileHandle,int &var,int bytes,int &numOfBytes,int overlapped);
int ReadFile(int fileHandle,short &buffer[],int bytes,int &numOfBytes,int overlapped);
int ReadFile(int fileHandle,char &buffer[],int bytes,int &numOfBytes,int overlapped);
//int ReadFile(int fileHandle,MqlTick &incoming,int bytes,int &numOfBytes,int overlapped);
int ReadFile(int fileHandle,int &incoming,int bytes,int &numOfBytes,int overlapped);
int CloseHandle(int fileHandle);
//int GetLastError(void);
int FlushFileBuffers(int pipeHandle);
int CreateDirectoryW(string name, int security);
#import


class CWin32File
  {
private:
   int               m_handle;
   void         CreateDirectory(string fileName);
public:
                     CWin32File();
                    ~CWin32File();
   bool              OpenR(string fileName);
   bool              OpenW(string fileName);
   bool              Close();
   bool              Read(char& buffer[]);
   bool              Write(char& buffer[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CWin32File::CWin32File()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CWin32File::~CWin32File()
  {
   if(m_handle!=INVALID_HANDLE_VALUE)
     {
      Close();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CWin32File::OpenR(string fileName)
  {
   m_handle = CreateFileW(fileName,               // file to open
                          (int)GENERIC_READ,          // open for reading
                          0,// share for reading
                          NULL,                  // default security
                          OPEN_EXISTING,         // existing file only
                          FILE_ATTRIBUTE_NORMAL, // normal file
                          NULL);
   if(m_handle==INVALID_HANDLE_VALUE)
     {
      return false;
     }
   return true;
  }
  
  void CWin32File::CreateDirectory(string fileName)
  {
    int idx = 0;
    int idx2;
    while(true)
    {
        idx2 = StringFind(fileName, "\\", idx);
        if (idx2 == -1)
            break;
        string s = StringSubstr(fileName, 0, idx2);
        CreateDirectoryW(s, 0);
        idx = idx2 + 1;
    }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CWin32File::OpenW(string fileName)
  {
    CreateDirectory(fileName);
    
   m_handle=CreateFileW(fileName,// file to open
                        (int)GENERIC_WRITE,// open for reading
                        0,// share for reading
                        NULL,// default security
                        CREATE_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL,// normal file
                        NULL);
   if(m_handle==INVALID_HANDLE_VALUE)
     {
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CWin32File::Close()
  {
    if (m_handle == INVALID_HANDLE_VALUE)
        return true;    
    int bErrorFlag = CloseHandle(m_handle);
    if (bErrorFlag == 0)
        return false;
    m_handle = -1;
    return true;
  }
//+------------------------------------------------------------------+

bool CWin32File::Write(char& buffer[])
{
    if (m_handle == INVALID_HANDLE_VALUE)
        return false;
    
    int dwBytesToWrite = ArraySize(buffer);
    int dwBytesWritten = 0;    
    int bErrorFlag = WriteFile( 
                    m_handle,           // open file handle
                    buffer,      // start of data to write
                    dwBytesToWrite,  // number of bytes to write
                    dwBytesWritten, // number of bytes that were written
                    NULL);            // no overlapped structure
    if (bErrorFlag == 0 || dwBytesWritten != dwBytesToWrite)
        return false;
    return true;
}

#define BUFFERSIZE 1024
bool CWin32File::Read(char &buffer[])
{
    if (m_handle == INVALID_HANDLE_VALUE)
        return false;

    int  dwBytesRead = 0;
    char   ReadBuffer[BUFFERSIZE];    
    ArrayResize(buffer, 0);
    int len = 0;
    while(true)
    {
        int bErrorFlag = ReadFile(
            m_handle, ReadBuffer, BUFFERSIZE, dwBytesRead, NULL);
        
        if (bErrorFlag == 0)
            break;
        if (dwBytesRead == 0)
            break;
        
        len += dwBytesRead;    
        ArrayResize(buffer, len, BUFFERSIZE);
        for(int i=0; i<dwBytesRead; ++i)
            buffer[len - dwBytesRead + i] = ReadBuffer[i];
    }
    
    return true;
}
