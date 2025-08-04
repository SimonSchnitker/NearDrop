class Progress
{
    int totalBytes = 0;
    int sentBytes = 0;

    get value
    {
        if (totalBytes == 0)
        {
            return 0.0;
        }

        return sentBytes / totalBytes;
    }

    Progress(this.totalBytes);
}