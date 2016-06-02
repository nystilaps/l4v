%
% Copyright 2014, General Dynamics C4 Systems
%
% This software may be distributed and modified according to the terms of
% the GNU General Public License version 2. Note that NO WARRANTY is provided.
% See "LICENSE_GPLv2.txt" for details.
%
% @TAG(GD_GPL)
%

This module specifies the mechanisms used by the seL4 kernel to handle failures in kernel operations that must be communicated somehow to user-level code.

> module SEL4.API.Failures where

\begin{impdetails}

> import SEL4.Machine
> import SEL4.API.Types

\end{impdetails}

\subsection{Types}

\subsubsection{Faults}

When user-level code causes a kernel event, processing of that event may fail in a manner that the current thread normally cannot or should not handle itself. When that occurs, a \emph{fault IPC} is sent to a designated fault handler. Such events typically include virtual memory or capability lookup failures, exceptions generated by the CPU, and interrupts from external hardware devices.

The procedure for handling faults is defined in \autoref{sec:kernel.faulthandler}; the fault messages sent and received by the kernel are defined in \autoref{sec:api.faults}.

> data Fault
>         = UserException {
>             userExceptionNumber :: Word,
>             userExceptionErrorCode :: Word }
>         | VMFault {
>             vmFaultAddress :: VPtr,
>             vmFaultArchData :: [Word] }
>         | CapFault {
>             capFaultAddress :: CPtr,
>             capFaultInReceivePhase :: Bool,
>             capFaultFailure :: LookupFailure }
>         | UnknownSyscallException {
>             unknownSyscallNumber :: Word }
>         deriving Show

\subsection{Kernel Init Failure}

Data type InitFailure can be thrown during SysInit

> data InitFailure = IFailure

\subsection{System Call Errors}

The following data type defines the set of errors that can be returned from a kernel object method call.

> data SyscallError
>         = IllegalOperation
>         | InvalidArgument {
>             invalidArgumentNumber :: Int }
>         | TruncatedMessage
>         | DeleteFirst
>         | RangeError {
>             rangeErrorMin, rangeErrorMax :: Word }
>         | FailedLookup {
>             failedLookupWasSource :: Bool,
>             failedLookupDescription :: LookupFailure }
>         | InvalidCapability {
>             invalidCapNumber :: Int }
>         | RevokeFirst
>         | NotEnoughMemory {
>             memoryLeft :: Word }
>         | AlignmentError
>         deriving Show

\subsubsection{Lookup Failures}

A capability or virtual address space lookup may fail in several different ways:

> data LookupFailure

\begin{itemize}

\item a slot on the lookup path contains no capability;

>         = MissingCapability {
>             missingCapBitsLeft :: Int }

\item there is no slot at the requested depth, or a page capability was found at the wrong depth;

>         | DepthMismatch {
>             depthMismatchBitsLeft :: Int,
>             depthMismatchBitsFound :: Int }

\item the root of the address space is not valid (that is, it is not of the correct type, or is not writable for the destination of a CNode operation, or is not readable for the source of a CNode operation);

>         | InvalidRoot

\item or there is a CNode with a guard making the requested slot unreachable.

>         | GuardMismatch {
>             guardMismatchBitsLeft :: Int,
>             guardMismatchGuardFound :: Word,
>             guardMismatchGuardSize :: Int }
>         deriving Show

\end{itemize}

\subsection{Sending Failure Messages}

The following function converts the Haskell model's "SyscallError" type into a message that can be sent to a user level thread via IPC. It returns a "(Word, [Word])" tuple; the first element is to be used as the label of the reply IPC.

There is a similar function used for the "Fault" type; it is defined in \autoref{sec:api.faults}.

> msgFromSyscallError :: SyscallError -> (Word, [Word])
>
> msgFromSyscallError (InvalidArgument n) = (1, [fromIntegral n])
>
> msgFromSyscallError (InvalidCapability n) = (2, [fromIntegral n])
>
> msgFromSyscallError IllegalOperation = (3, [])
>
> msgFromSyscallError (RangeError minV maxV) = (4, [minV, maxV])
>
> msgFromSyscallError AlignmentError = (5, [])
>
> msgFromSyscallError (FailedLookup s lf) =
>     (6, (fromIntegral $ fromEnum s):(msgFromLookupFailure lf))
>     
> msgFromSyscallError TruncatedMessage = (7, [])
>
> msgFromSyscallError DeleteFirst = (8, [])
>
> msgFromSyscallError RevokeFirst = (9, [])
>
> msgFromSyscallError (NotEnoughMemory n) = (10, [n])

\subsubsection{Lookup Failures}

Faults and system call errors may both be caused by a failed address space lookup. This function generates a sequence of words explaining the cause of the failure, and is used for both faults and system call replies.

> msgFromLookupFailure :: LookupFailure -> [Word]
>
> msgFromLookupFailure InvalidRoot = [1]
>
> msgFromLookupFailure (MissingCapability bl) = [2, fromIntegral bl]
>
> msgFromLookupFailure (DepthMismatch bl bf) =
>     [3, fromIntegral bl, fromIntegral bf]
>
> msgFromLookupFailure (GuardMismatch bl g gs) =
>     [4, fromIntegral bl, g, fromIntegral gs]

