import React, { useState, useEffect } from 'react';
import { 
  MessageSquare, 
  Mail, 
  Lock, 
  User, 
  AtSign, 
  Eye, 
  EyeOff, 
  ArrowRight, 
  ArrowLeft,
  CheckCircle2, 
  AlertCircle, 
  LogOut, 
  Settings, 
  ShieldCheck, 
  Users, 
  Search, 
  RefreshCw, 
  Sparkles,
  Smartphone,
  Flame,
  FileCode2,
  Bell,
  X,
  MoreVertical,
  Share2,
  Flag,
  Ban,
  Calendar,
  UserPlus,
  Check,
  ChevronRight,
  Send,
  Image as ImageIcon,
  CheckCheck
} from 'lucide-react';

interface MockUser {
  uid: string;
  email: string;
  displayName: string;
  username: string;
  photoUrl: string | null;
  bio: string;
  friendsCount: number;
  followersCount: number;
  followingCount: number;
  isOnline: boolean;
  joinedDate: string;
}

interface MockMessage {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  time: string;
  isRead: boolean;
}

interface MockNotification {
  id: string;
  type: 'new_follower' | 'mutual_friend' | 'chat_message' | 'group_invitation' | 'group_role_change' | 'group_member_removed';
  title: string;
  message: string;
  senderId?: string;
  senderName?: string;
  groupId?: string;
  groupName?: string;
  time: string;
  isRead: boolean;
}

type ScreenType = 'splash' | 'login' | 'register' | 'forgot_password' | 'home';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<ScreenType>('splash');
  const [currentUser, setCurrentUser] = useState<MockUser | null>(null);
  const [activeTab, setActiveTab] = useState<'chats' | 'explore' | 'friends' | 'profile'>('chats');
  
  // Auth Form States
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  
  // Feedback states
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);
  const [themeMode, setThemeMode] = useState<'light' | 'dark'>('light');
  const [activeViewTab, setActiveViewTab] = useState<'preview' | 'code' | 'rules'>('preview');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Settings Screen modal/state
  const [showSettingsModal, setShowSettingsModal] = useState(false);

  // In-App Activity & Notification modal/state
  const [showNotificationsModal, setShowNotificationsModal] = useState(false);
  const [notificationFilter, setNotificationFilter] = useState<'all' | 'unread'>('all');
  const [notifications, setNotifications] = useState<MockNotification[]>([
    {
      id: 'notif_1',
      type: 'new_follower',
      title: 'New Follower',
      message: 'Elena Rostova started following you.',
      senderId: 'user_elena',
      senderName: 'Elena Rostova',
      time: '10m ago',
      isRead: false,
    },
    {
      id: 'notif_2',
      type: 'mutual_friend',
      title: 'Mutual Friend! 🎉',
      message: 'You and Maya Lin are now mutual friends!',
      senderId: 'user_maya',
      senderName: 'Maya Lin',
      time: '1h ago',
      isRead: false,
    },
    {
      id: 'notif_3',
      type: 'group_invitation',
      title: 'Group Circle Invite',
      message: 'David K. invited you to join "Anime & Gaming Squad".',
      senderId: 'user_david',
      senderName: 'David K.',
      groupId: 'group_anime',
      groupName: 'Anime & Gaming Squad',
      time: 'Yesterday',
      isRead: true,
    },
    {
      id: 'notif_4',
      type: 'chat_message',
      title: 'David K.',
      message: 'Sent you the ticket link for tomorrow night’s live concert!',
      senderId: 'user_david',
      senderName: 'David K.',
      time: 'Yesterday',
      isRead: true,
    },
  ]);

  // Other User Profile modal state
  const [selectedOtherUser, setSelectedOtherUser] = useState<MockUser | null>(null);
  const [isFollowingSelected, setIsFollowingSelected] = useState(false);
  const [showMoreMenu, setShowMoreMenu] = useState(false);

  // Search query
  const [searchQuery, setSearchQuery] = useState('');

  // 1-to-1 Real-time Chat States
  const [activeChatUser, setActiveChatUser] = useState<MockUser | null>(null);
  const [chatInputText, setChatInputText] = useState('');
  const [messagesMap, setMessagesMap] = useState<Record<string, MockMessage[]>>({
    user_maya: [
      {
        id: 'msg_m1',
        senderId: 'user_maya',
        senderName: 'Maya Lin',
        text: 'Hey! Did you catch the new anime season premiere?! 🍿',
        time: '9:40 AM',
        isRead: true,
      },
      {
        id: 'msg_m2',
        senderId: 'current',
        senderName: 'You',
        text: 'Yes! The animation in episode 1 was unbelievable 🔥',
        time: '9:42 AM',
        isRead: true,
      },
    ],
    user_david: [
      {
        id: 'msg_d1',
        senderId: 'user_david',
        senderName: 'David K.',
        text: 'Sent you the ticket link for tomorrow night’s live concert!',
        time: 'Yesterday',
        isRead: true,
      },
    ],
    user_elena: [
      {
        id: 'msg_e1',
        senderId: 'user_elena',
        senderName: 'Elena Rostova',
        text: 'Thanks for the follow! Love your fan collection post.',
        time: 'Aug 14',
        isRead: true,
      },
    ],
  });

  const [chatConversations, setChatConversations] = useState<Array<{
    userUid: string;
    lastMessage: string;
    time: string;
    unread: number;
  }>>([
    {
      userUid: 'user_maya',
      lastMessage: 'Yes! The animation in episode 1 was unbelievable 🔥',
      time: '9:42 AM',
      unread: 0,
    },
    {
      userUid: 'user_david',
      lastMessage: 'Sent you the ticket link for tomorrow night’s live concert!',
      time: 'Yesterday',
      unread: 1,
    },
    {
      userUid: 'user_elena',
      lastMessage: 'Thanks for the follow! Love your fan collection post.',
      time: 'Aug 14',
      unread: 0,
    },
  ]);

  // Sample explore / other users
  const [otherUsers, setOtherUsers] = useState<MockUser[]>([
    {
      uid: 'user_maya',
      email: 'maya@heyfans.app',
      displayName: 'Maya Lin',
      username: 'mayafans',
      photoUrl: null,
      bio: 'Anime & Gaming fandom enthusiast 🎮✨ Streaming weekly!',
      friendsCount: 45,
      followersCount: 342,
      followingCount: 120,
      isOnline: true,
      joinedDate: 'January 2026',
    },
    {
      uid: 'user_david',
      email: 'david@heyfans.app',
      displayName: 'David K.',
      username: 'david_music',
      photoUrl: null,
      bio: 'Concert goer & Vinyl collector 🎵 Music connects us.',
      friendsCount: 112,
      followersCount: 890,
      followingCount: 310,
      isOnline: false,
      joinedDate: 'November 2025',
    },
    {
      uid: 'user_elena',
      email: 'elena@heyfans.app',
      displayName: 'Elena Rostova',
      username: 'elena_r',
      photoUrl: null,
      bio: 'Pop music producer & sound designer 🎹 Synthwave lover.',
      friendsCount: 94,
      followersCount: 520,
      followingCount: 280,
      isOnline: true,
      joinedDate: 'December 2025',
    },
    {
      uid: 'user_marcus',
      email: 'marcus@heyfans.app',
      displayName: 'Marcus Vance',
      username: 'marcus_v',
      photoUrl: null,
      bio: 'Movie critic & Sci-Fi fan 🎬🍿 Discussing cinematic universes.',
      friendsCount: 82,
      followersCount: 640,
      followingCount: 190,
      isOnline: false,
      joinedDate: 'February 2026',
    },
  ]);

  // Show temporary toast notification
  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 2800);
  };

  // Splash Screen automatic timeout check
  useEffect(() => {
    if (currentScreen === 'splash') {
      const timer = setTimeout(() => {
        if (currentUser) {
          setCurrentScreen('home');
        } else {
          setCurrentScreen('login');
        }
      }, 1400);
      return () => clearTimeout(timer);
    }
  }, [currentScreen, currentUser]);

  const handleLogin = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setErrorMessage(null);
    if (!email || !password) {
      setErrorMessage('Please fill in all required fields.');
      return;
    }
    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters.');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      const user: MockUser = {
        uid: 'usr_sample_' + Math.floor(Math.random() * 10000),
        email: email.trim().toLowerCase(),
        displayName: email.split('@')[0].toUpperCase(),
        username: email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, ''),
        photoUrl: null,
        bio: 'Hey Fans verified community member 🔥',
        friendsCount: 56,
        followersCount: 142,
        followingCount: 88,
        isOnline: true,
        joinedDate: 'March 2026',
      };
      setCurrentUser(user);
      setCurrentScreen('home');
      showToast(`Welcome back, ${user.displayName}!`);
    }, 600);
  };

  const handleRegister = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setErrorMessage(null);
    if (!displayName || !username || !email || !password) {
      setErrorMessage('Please complete all registration fields.');
      return;
    }
    const cleanUser = username.trim().toLowerCase();
    if (cleanUser.length < 3 || !/^[a-z0-9_]+$/.test(cleanUser)) {
      setErrorMessage('Username must be 3-20 characters with lowercase letters, numbers, or underscores.');
      return;
    }
    if (cleanUser === 'admin' || cleanUser === 'heyfans') {
      setErrorMessage(`The username @${cleanUser} is already taken by another fan.`);
      return;
    }
    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters.');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      const user: MockUser = {
        uid: 'usr_reg_' + Date.now(),
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
        username: cleanUser,
        photoUrl: null,
        bio: 'Just joined Hey Fans! ✨ Ready to connect.',
        friendsCount: 0,
        followersCount: 0,
        followingCount: 0,
        isOnline: true,
        joinedDate: 'March 2026',
      };
      setCurrentUser(user);
      setCurrentScreen('home');
      showToast('Account created successfully!');
    }, 700);
  };

  const handleForgotPassword = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setErrorMessage(null);
    if (!email || !email.includes('@')) {
      setErrorMessage('Please enter a valid email address.');
      return;
    }
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      setResetSent(true);
    }, 550);
  };

  const handleLogout = () => {
    setCurrentUser(null);
    setShowSettingsModal(false);
    setSelectedOtherUser(null);
    setCurrentScreen('login');
    setActiveTab('chats');
    setEmail('');
    setPassword('');
    setDisplayName('');
    setUsername('');
    setResetSent(false);
    setErrorMessage(null);
    showToast('Signed out of Hey Fans.');
  };

  const openOtherUserProfile = (user: MockUser) => {
    setSelectedOtherUser(user);
    setIsFollowingSelected(false);
    setShowMoreMenu(false);
  };

  const toggleFollowUser = () => {
    if (!selectedOtherUser || !currentUser) return;
    const newFollowingState = !isFollowingSelected;
    setIsFollowingSelected(newFollowingState);

    // If target already follows current user (e.g. Maya Lin who follows current user)
    const targetFollowsCurrent = selectedOtherUser.uid === 'user_2'; // Elena follows current user

    // Update target user counts
    setOtherUsers(prev => prev.map(u => {
      if (u.uid === selectedOtherUser.uid) {
        return {
          ...u,
          followersCount: Math.max(0, u.followersCount + (newFollowingState ? 1 : -1)),
          friendsCount: targetFollowsCurrent
            ? Math.max(0, u.friendsCount + (newFollowingState ? 1 : -1))
            : u.friendsCount,
        };
      }
      return u;
    }));

    // Update current user counts
    setCurrentUser({
      ...currentUser,
      followingCount: Math.max(0, currentUser.followingCount + (newFollowingState ? 1 : -1)),
      friendsCount: targetFollowsCurrent
        ? Math.max(0, currentUser.friendsCount + (newFollowingState ? 1 : -1))
        : currentUser.friendsCount,
    });

    if (newFollowingState) {
      if (targetFollowsCurrent) {
        showToast(`Mutual follow! You and @${selectedOtherUser.username} are now Friends 🎉`);
      } else {
        showToast(`Now following @${selectedOtherUser.username}`);
      }
    } else {
      showToast(`Unfollowed @${selectedOtherUser.username}`);
    }
  };

  const openChatWithUser = (user: MockUser) => {
    setSelectedOtherUser(null);
    setActiveChatUser(user);
    setChatInputText('');
    
    // Mark conversation unread count as 0
    setChatConversations(prev => prev.map(c => 
      c.userUid === user.uid ? { ...c, unread: 0 } : c
    ));
    
    // If not exists in conversation list, add it
    setChatConversations(prev => {
      if (prev.some(c => c.userUid === user.uid)) return prev;
      return [
        {
          userUid: user.uid,
          lastMessage: 'Tap to start direct conversation',
          time: 'Just now',
          unread: 0,
        },
        ...prev,
      ];
    });

    // If messagesMap empty for user, init with greeting
    setMessagesMap(prev => {
      if (prev[user.uid]) return prev;
      return {
        ...prev,
        [user.uid]: [
          {
            id: `init_${Date.now()}`,
            senderId: user.uid,
            senderName: user.displayName,
            text: `Hey! Thanks for messaging me on Hey Fans 👋 Let's connect!`,
            time: 'Just now',
            isRead: true,
          }
        ]
      };
    });
  };

  const sendChatMessage = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!activeChatUser || !chatInputText.trim() || !currentUser) return;

    const textToSend = chatInputText.trim();
    const newMsg: MockMessage = {
      id: `msg_${Date.now()}`,
      senderId: 'current',
      senderName: currentUser.displayName,
      text: textToSend,
      time: 'Just now',
      isRead: false,
    };

    setMessagesMap(prev => ({
      ...prev,
      [activeChatUser.uid]: [...(prev[activeChatUser.uid] || []), newMsg],
    }));

    setChatConversations(prev => {
      const filtered = prev.filter(c => c.userUid !== activeChatUser.uid);
      return [
        {
          userUid: activeChatUser.uid,
          lastMessage: textToSend,
          time: 'Just now',
          unread: 0,
        },
        ...filtered,
      ];
    });

    setChatInputText('');

    // Simulate realistic live receive from the other user
    setTimeout(() => {
      const replyMsg: MockMessage = {
        id: `reply_${Date.now()}`,
        senderId: activeChatUser.uid,
        senderName: activeChatUser.displayName,
        text: `Got your message! Excited to collaborate in Hey Fans 🔥`,
        time: 'Just now',
        isRead: true,
      };

      setMessagesMap(prev => ({
        ...prev,
        [activeChatUser.uid]: [...(prev[activeChatUser.uid] || []).map(m => ({ ...m, isRead: true })), replyMsg],
      }));

      setChatConversations(prev => {
        const filtered = prev.filter(c => c.userUid !== activeChatUser.uid);
        return [
          {
            userUid: activeChatUser.uid,
            lastMessage: replyMsg.text,
            time: 'Just now',
            unread: 0,
          },
          ...filtered,
        ];
      });
    }, 1200);
  };

  const filteredUsers = otherUsers.filter(u => 
    u.displayName.toLowerCase().includes(searchQuery.toLowerCase()) || 
    u.username.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className={`min-h-screen ${themeMode === 'dark' ? 'bg-[#0B0F19] text-slate-100' : 'bg-[#F8FAFC] text-slate-900'} flex flex-col font-sans transition-colors`}>
      
      {/* Header bar */}
      <header className="border-b border-slate-200 dark:border-slate-800 bg-white/80 dark:bg-[#151C2C]/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#6366F1] to-[#4F46E5] flex items-center justify-center shadow-md shadow-indigo-500/20 text-white">
              <MessageSquare className="w-5 h-5 fill-white/20" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-lg tracking-tight bg-gradient-to-r from-[#6366F1] to-[#EC4899] bg-clip-text text-transparent">
                  Hey Fans
                </span>
                <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-[#6366F1] border border-indigo-200 dark:border-indigo-800">
                  CORE DESIGN SYNC
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                UI/UX Source of Truth & Clean Architecture
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex bg-slate-100 dark:bg-slate-800 p-1 rounded-xl border border-slate-200 dark:border-slate-700">
              <button
                onClick={() => setActiveViewTab('preview')}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all flex items-center gap-1.5 ${
                  activeViewTab === 'preview'
                    ? 'bg-white dark:bg-[#151C2C] text-[#6366F1] shadow-sm'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <Smartphone className="w-3.5 h-3.5" />
                Live Mobile UI
              </button>
              <button
                onClick={() => setActiveViewTab('code')}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all flex items-center gap-1.5 ${
                  activeViewTab === 'code'
                    ? 'bg-white dark:bg-[#151C2C] text-[#6366F1] shadow-sm'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <FileCode2 className="w-3.5 h-3.5" />
                Dart Architecture
              </button>
              <button
                onClick={() => setActiveViewTab('rules')}
                className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all flex items-center gap-1.5 ${
                  activeViewTab === 'rules'
                    ? 'bg-white dark:bg-[#151C2C] text-[#6366F1] shadow-sm'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                }`}
              >
                <ShieldCheck className="w-3.5 h-3.5" />
                Security Rules
              </button>
            </div>

            <button
              onClick={() => setThemeMode(themeMode === 'light' ? 'dark' : 'light')}
              className="p-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 transition"
              title="Toggle theme preview"
            >
              {themeMode === 'light' ? '🌙' : '☀️'}
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Column: Specs, Verification & Navigation Helper */}
        <div className="lg:col-span-4 space-y-4">
          
          {/* Profile & Navigation Verification Card */}
          <div className="bg-white dark:bg-[#151C2C] p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-3.5">
            <div className="flex items-center justify-between">
              <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 flex items-center gap-2">
                <Flame className="w-4 h-4 text-orange-500" />
                Design Rules Checklist
              </h2>
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            </div>

            <div className="space-y-2 text-xs">
              <div className="flex items-start gap-2 p-2 rounded-lg bg-slate-50 dark:bg-[#0B0F19] border border-slate-200 dark:border-slate-800">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-slate-800 dark:text-slate-200">Stats Order:</span>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                    <span className="font-bold text-[#6366F1]">Friends</span> → <span className="font-bold text-[#6366F1]">Followers</span> → <span className="font-bold text-[#6366F1]">Following</span>
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-2 p-2 rounded-lg bg-slate-50 dark:bg-[#0B0F19] border border-slate-200 dark:border-slate-800">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-slate-800 dark:text-slate-200">Settings Button Rule:</span>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                    Visible ONLY on user's own profile screen. Excluded from Search, Friends, Chats, and Other user profiles.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-2 p-2 rounded-lg bg-slate-50 dark:bg-[#0B0F19] border border-slate-200 dark:border-slate-800">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-slate-800 dark:text-slate-200">Other User Profile Modal:</span>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                    [X] Close & [⋮] More Menu (Share / Report / Block). Equal-width [Message] and [Follow] buttons.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-2 p-2 rounded-lg bg-slate-50 dark:bg-[#0B0F19] border border-slate-200 dark:border-slate-800">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-slate-800 dark:text-slate-200">1-to-1 Direct Messaging:</span>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5">
                    Deterministic Chat ID (<code className="text-[#6366F1]">uidA_uidB</code>), real-time Firestore message stream, atomic parent update, and read status.
                  </p>
                </div>
              </div>
            </div>

            {/* Quick Screen Switcher */}
            <div className="pt-2 border-t border-slate-100 dark:border-slate-800">
              <div className="text-[11px] font-semibold text-slate-500 mb-2">AUTH FLOW CONTROLS:</div>
              <div className="grid grid-cols-2 gap-1.5">
                <button
                  onClick={() => { setCurrentScreen('splash'); setErrorMessage(null); }}
                  className={`px-2.5 py-1.5 rounded-lg text-xs font-medium border text-left transition ${
                    currentScreen === 'splash'
                      ? 'bg-indigo-50 border-indigo-300 text-indigo-700 dark:bg-indigo-950/50 dark:border-indigo-700 dark:text-indigo-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  1. Splash
                </button>
                <button
                  onClick={() => { setCurrentScreen('login'); setErrorMessage(null); }}
                  className={`px-2.5 py-1.5 rounded-lg text-xs font-medium border text-left transition ${
                    currentScreen === 'login'
                      ? 'bg-indigo-50 border-indigo-300 text-indigo-700 dark:bg-indigo-950/50 dark:border-indigo-700 dark:text-indigo-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  2. Login
                </button>
                <button
                  onClick={() => { setCurrentScreen('register'); setErrorMessage(null); }}
                  className={`px-2.5 py-1.5 rounded-lg text-xs font-medium border text-left transition ${
                    currentScreen === 'register'
                      ? 'bg-indigo-50 border-indigo-300 text-indigo-700 dark:bg-indigo-950/50 dark:border-indigo-700 dark:text-indigo-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  3. Register
                </button>
                <button
                  onClick={() => { setCurrentScreen('forgot_password'); setResetSent(false); setErrorMessage(null); }}
                  className={`px-2.5 py-1.5 rounded-lg text-xs font-medium border text-left transition ${
                    currentScreen === 'forgot_password'
                      ? 'bg-indigo-50 border-indigo-300 text-indigo-700 dark:bg-indigo-950/50 dark:border-indigo-700 dark:text-indigo-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  4. Forgot Pass
                </button>
              </div>
            </div>
          </div>

          {/* Quick Fill Test Accounts */}
          <div className="bg-gradient-to-br from-indigo-500/10 via-purple-500/5 to-pink-500/10 dark:from-indigo-950/40 dark:to-pink-950/20 p-5 rounded-2xl border border-indigo-200/60 dark:border-indigo-800/40 text-xs space-y-2">
            <h3 className="font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-[#6366F1]" />
              Quick Fill Credentials
            </h3>
            <p className="text-slate-600 dark:text-slate-400 text-[11px]">
              Click below to test login with pre-configured accounts:
            </p>
            <div className="space-y-1.5 pt-1">
              <button
                onClick={() => {
                  setEmail('rakib@heyfans.app');
                  setPassword('securePass123!');
                  setDisplayName('Rakib Hasan');
                  setUsername('rakib_fan');
                  if (currentScreen !== 'login' && currentScreen !== 'register') {
                    setCurrentScreen('login');
                  }
                }}
                className="w-full text-left p-2 rounded-lg bg-white dark:bg-[#151C2C] border border-slate-200 dark:border-slate-700 hover:border-indigo-400 transition"
              >
                <div className="font-semibold text-slate-800 dark:text-slate-200">Rakib Hasan</div>
                <div className="text-[10px] text-slate-500">rakib@heyfans.app • @rakib_fan</div>
              </button>
              <button
                onClick={() => {
                  setEmail('sarah@heyfans.app');
                  setPassword('starWars2026');
                  setDisplayName('Sarah Connor');
                  setUsername('sarah_star');
                  if (currentScreen !== 'login' && currentScreen !== 'register') {
                    setCurrentScreen('login');
                  }
                }}
                className="w-full text-left p-2 rounded-lg bg-white dark:bg-[#151C2C] border border-slate-200 dark:border-slate-700 hover:border-indigo-400 transition"
              >
                <div className="font-semibold text-slate-800 dark:text-slate-200">Sarah Connor</div>
                <div className="text-[10px] text-slate-500">sarah@heyfans.app • @sarah_star</div>
              </button>
            </div>
          </div>

        </div>

        {/* Center / Right Column: Interactive Mobile Mockup or Code Inspector */}
        <div className="lg:col-span-8 flex justify-center">
          {activeViewTab === 'preview' && (
            <div className="w-full max-w-[390px] h-[780px] bg-white dark:bg-[#0B0F19] rounded-[42px] border-[8px] border-slate-800 dark:border-slate-700 shadow-2xl overflow-hidden flex flex-col relative transition-all">
              
              {/* Dynamic Island / Top Notch */}
              <div className="w-full pt-3 pb-1 px-6 flex justify-between items-center z-30 select-none bg-transparent">
                <span className="text-[12px] font-bold tracking-tight">9:41</span>
                <div className="w-24 h-4 bg-slate-900 rounded-full flex items-center justify-center">
                  <div className="w-2.5 h-2.5 rounded-full bg-slate-800 mr-2" />
                  <div className="w-2 h-2 rounded-full bg-indigo-900" />
                </div>
                <div className="flex items-center gap-1.5 text-xs font-semibold">
                  <span>5G</span>
                  <div className="w-4 h-2.5 border border-current rounded-sm p-[1px]">
                    <div className="w-full h-full bg-current rounded-2xs" />
                  </div>
                </div>
              </div>

              {/* Toast Feedback Notification */}
              {toastMessage && (
                <div className="absolute top-12 left-4 right-4 z-50 bg-[#6366F1] text-white text-xs font-semibold py-2.5 px-4 rounded-xl shadow-lg flex items-center gap-2 animate-fade-in">
                  <CheckCircle2 className="w-4 h-4 shrink-0" />
                  <span>{toastMessage}</span>
                </div>
              )}

              {/* SCREEN CONTENT */}
              <div className="flex-1 overflow-y-auto flex flex-col relative">
                
                {/* 1. SPLASH SCREEN */}
                {currentScreen === 'splash' && (
                  <div className="flex-1 bg-gradient-to-br from-[#6366F1] to-[#4F46E5] flex flex-col items-center justify-center p-6 text-white text-center animate-fade-in">
                    <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center shadow-xl mb-6">
                      <MessageSquare className="w-10 h-10 text-[#6366F1]" />
                    </div>
                    <h1 className="text-3xl font-extrabold tracking-tight">Hey Fans</h1>
                    <p className="mt-2 text-xs bg-white/20 px-3.5 py-1 rounded-full font-medium">
                      Social Messaging for Fans & Communities
                    </p>
                    <div className="mt-8 flex items-center gap-2 text-white/80 text-xs">
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      Checking session...
                    </div>
                  </div>
                )}

                {/* 2. LOGIN SCREEN */}
                {currentScreen === 'login' && (
                  <div className="flex-1 p-6 flex flex-col justify-between bg-white dark:bg-[#0B0F19]">
                    <div className="space-y-6">
                      <div className="flex items-center gap-3 pt-2">
                        <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#6366F1] to-[#4F46E5] flex items-center justify-center text-white shadow">
                          <MessageSquare className="w-5 h-5" />
                        </div>
                        <span className="font-extrabold text-xl tracking-tight text-slate-900 dark:text-white">
                          Hey Fans
                        </span>
                      </div>

                      <div className="pt-2">
                        <h2 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">
                          Welcome back
                        </h2>
                        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                          Sign in to join your fan communities and direct chats.
                        </p>
                      </div>

                      {errorMessage && (
                        <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-rose-600 dark:text-rose-400 text-xs flex items-start gap-2">
                          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                          <span>{errorMessage}</span>
                        </div>
                      )}

                      <form onSubmit={handleLogin} className="space-y-4">
                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1.5">
                            Email Address
                          </label>
                          <div className="relative">
                            <Mail className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type="email"
                              value={email}
                              onChange={(e) => setEmail(e.target.value)}
                              placeholder="fan@heyfans.app"
                              className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1.5">
                            Password
                          </label>
                          <div className="relative">
                            <Lock className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type={showPassword ? 'text' : 'password'}
                              value={password}
                              onChange={(e) => setPassword(e.target.value)}
                              placeholder="••••••••"
                              className="w-full pl-10 pr-10 py-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                            <button
                              type="button"
                              onClick={() => setShowPassword(!showPassword)}
                              className="absolute right-3.5 top-3.5 text-slate-400 hover:text-slate-600"
                            >
                              {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                            </button>
                          </div>
                        </div>

                        <div className="text-right">
                          <button
                            type="button"
                            onClick={() => { setErrorMessage(null); setCurrentScreen('forgot_password'); }}
                            className="text-xs font-semibold text-[#6366F1] hover:underline"
                          >
                            Forgot password?
                          </button>
                        </div>

                        <button
                          type="submit"
                          disabled={isLoading}
                          className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white font-semibold text-sm shadow-md shadow-indigo-500/25 hover:opacity-95 transition flex items-center justify-center gap-2"
                        >
                          {isLoading ? (
                            <RefreshCw className="w-4 h-4 animate-spin" />
                          ) : (
                            <>
                              <span>Sign In</span>
                              <ArrowRight className="w-4 h-4" />
                            </>
                          )}
                        </button>
                      </form>
                    </div>

                    <div className="pt-6 pb-2 text-center text-xs text-slate-500 dark:text-slate-400">
                      Don't have an account?{' '}
                      <button
                        onClick={() => { setErrorMessage(null); setCurrentScreen('register'); }}
                        className="font-bold text-[#6366F1] hover:underline"
                      >
                        Create Account
                      </button>
                    </div>
                  </div>
                )}

                {/* 3. REGISTER SCREEN */}
                {currentScreen === 'register' && (
                  <div className="flex-1 p-6 flex flex-col justify-between bg-white dark:bg-[#0B0F19]">
                    <div className="space-y-4">
                      <div>
                        <button
                          onClick={() => { setErrorMessage(null); setCurrentScreen('login'); }}
                          className="text-xs text-[#6366F1] font-semibold flex items-center gap-1 mb-3"
                        >
                          ← Back to Login
                        </button>
                        <h2 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">
                          Join Hey Fans
                        </h2>
                        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                          Create your profile handle and connect with fans.
                        </p>
                      </div>

                      {errorMessage && (
                        <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-rose-600 dark:text-rose-400 text-xs flex items-start gap-2">
                          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                          <span>{errorMessage}</span>
                        </div>
                      )}

                      <form onSubmit={handleRegister} className="space-y-3">
                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
                            Display Name
                          </label>
                          <div className="relative">
                            <User className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type="text"
                              value={displayName}
                              onChange={(e) => setDisplayName(e.target.value)}
                              placeholder="Alex Parker"
                              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
                            Unique Handle (@username)
                          </label>
                          <div className="relative">
                            <AtSign className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type="text"
                              value={username}
                              onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                              placeholder="alexparker"
                              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm font-mono focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
                            Email Address
                          </label>
                          <div className="relative">
                            <Mail className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type="email"
                              value={email}
                              onChange={(e) => setEmail(e.target.value)}
                              placeholder="alex@example.com"
                              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1">
                            Password
                          </label>
                          <div className="relative">
                            <Lock className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                            <input
                              type={showPassword ? 'text' : 'password'}
                              value={password}
                              onChange={(e) => setPassword(e.target.value)}
                              placeholder="••••••••"
                              className="w-full pl-10 pr-10 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                              required
                            />
                            <button
                              type="button"
                              onClick={() => setShowPassword(!showPassword)}
                              className="absolute right-3.5 top-3 text-slate-400"
                            >
                              {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                            </button>
                          </div>
                        </div>

                        <button
                          type="submit"
                          disabled={isLoading}
                          className="w-full mt-2 py-3 rounded-xl bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white font-semibold text-sm shadow-md shadow-indigo-500/25 hover:opacity-95 transition flex items-center justify-center gap-2"
                        >
                          {isLoading ? (
                            <RefreshCw className="w-4 h-4 animate-spin" />
                          ) : (
                            <span>Create Account</span>
                          )}
                        </button>
                      </form>
                    </div>

                    <div className="pt-3 text-center text-xs text-slate-500 dark:text-slate-400">
                      Already have an account?{' '}
                      <button
                        onClick={() => { setErrorMessage(null); setCurrentScreen('login'); }}
                        className="font-bold text-[#6366F1] hover:underline"
                      >
                        Sign In
                      </button>
                    </div>
                  </div>
                )}

                {/* 4. FORGOT PASSWORD */}
                {currentScreen === 'forgot_password' && (
                  <div className="flex-1 p-6 flex flex-col justify-between bg-white dark:bg-[#0B0F19]">
                    <div className="space-y-5">
                      <button
                        onClick={() => { setErrorMessage(null); setCurrentScreen('login'); }}
                        className="text-xs text-[#6366F1] font-semibold flex items-center gap-1"
                      >
                        ← Back to Login
                      </button>

                      {!resetSent ? (
                        <>
                          <div>
                            <h2 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">
                              Reset Password
                            </h2>
                            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                              Enter your registered email address and we'll send you password reset instructions.
                            </p>
                          </div>

                          {errorMessage && (
                            <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-rose-600 dark:text-rose-400 text-xs flex items-start gap-2">
                              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                              <span>{errorMessage}</span>
                            </div>
                          )}

                          <form onSubmit={handleForgotPassword} className="space-y-4">
                            <div>
                              <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 mb-1.5">
                                Registered Email
                              </label>
                              <div className="relative">
                                <Mail className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
                                <input
                                  type="email"
                                  value={email}
                                  onChange={(e) => setEmail(e.target.value)}
                                  placeholder="fan@heyfans.app"
                                  className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#151C2C] text-sm focus:outline-none focus:border-[#6366F1] dark:text-white"
                                  required
                                />
                              </div>
                            </div>

                            <button
                              type="submit"
                              disabled={isLoading}
                              className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white font-semibold text-sm shadow-md shadow-indigo-500/25 hover:opacity-95 transition flex items-center justify-center gap-2"
                            >
                              {isLoading ? (
                                <RefreshCw className="w-4 h-4 animate-spin" />
                              ) : (
                                <span>Send Reset Link</span>
                              )}
                            </button>
                          </form>
                        </>
                      ) : (
                        <div className="text-center py-8 space-y-4">
                          <div className="w-16 h-16 bg-emerald-100 dark:bg-emerald-950/60 text-emerald-500 rounded-full flex items-center justify-center mx-auto">
                            <CheckCircle2 className="w-8 h-8" />
                          </div>
                          <h3 className="text-xl font-bold text-slate-900 dark:text-white">
                            Check Your Inbox
                          </h3>
                          <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                            We've dispatched recovery instructions to <span className="font-semibold text-slate-800 dark:text-slate-200">{email}</span>.
                          </p>
                          <button
                            onClick={() => { setResetSent(false); setCurrentScreen('login'); }}
                            className="mt-4 px-6 py-2.5 rounded-xl bg-[#6366F1] text-white text-xs font-semibold shadow"
                          >
                            Back to Sign In
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {/* 5. AUTHENTICATED HOME SCREEN */}
                {currentScreen === 'home' && currentUser && (
                  <div className="flex-1 flex flex-col bg-slate-50 dark:bg-[#0B0F19]">
                    
                    {/* Top App Bar - NOTICE: Settings button appears ONLY on Profile tab */}
                    <div className="p-4 bg-white dark:bg-[#151C2C] border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white font-bold text-xs flex items-center justify-center">
                          {currentUser.displayName[0]}
                        </div>
                        <div>
                          <div className="text-xs font-bold text-slate-900 dark:text-white">
                            {activeTab === 'chats' && 'Messages'}
                            {activeTab === 'explore' && 'Explore Fans'}
                            {activeTab === 'friends' && 'Mutual Friends'}
                            {activeTab === 'profile' && 'My Profile'}
                          </div>
                          <div className="text-[10px] text-emerald-500 font-semibold flex items-center gap-1">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                            Online
                          </div>
                        </div>
                      </div>

                      {/* Right Action on Top Bar */}
                      <div>
                        {activeTab === 'profile' ? (
                          // Settings Button ONLY ON PROFILE
                          <button
                            onClick={() => setShowSettingsModal(true)}
                            title="Settings"
                            className="p-2 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                          >
                            <Settings className="w-4 h-4" />
                          </button>
                        ) : (
                          // Notification icon with real-time unread badge
                          <button
                            onClick={() => setShowNotificationsModal(true)}
                            title="Notifications & Activity"
                            className="relative p-2 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                          >
                            <Bell className={`w-4 h-4 ${notifications.filter(n => !n.isRead).length > 0 ? 'text-[#6366F1]' : ''}`} />
                            {notifications.filter(n => !n.isRead).length > 0 && (
                              <span className="absolute top-1.5 right-1.5 w-4 h-4 bg-rose-500 text-white rounded-full text-[9px] font-extrabold flex items-center justify-center border-2 border-white dark:border-[#151C2C]">
                                {notifications.filter(n => !n.isRead).length}
                              </span>
                            )}
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Tab Body */}
                    <div className="flex-1 overflow-y-auto p-4">
                      
                      {/* TAB 1: CHATS */}
                      {activeTab === 'chats' && (
                        <div className="space-y-3">
                          <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-1 flex justify-between items-center">
                            <span>Direct Messages ({chatConversations.length})</span>
                            <span className="text-[10px] text-emerald-500 font-semibold flex items-center gap-1">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                              Real-Time Stream
                            </span>
                          </div>

                          <div className="space-y-2">
                            {chatConversations.map((conv) => {
                              const targetUser = otherUsers.find(u => u.uid === conv.userUid) || {
                                uid: conv.userUid,
                                displayName: 'Hey Fans Member',
                                username: 'member',
                                isOnline: true,
                              };

                              return (
                                <div
                                  key={conv.userUid}
                                  onClick={() => openChatWithUser(targetUser as MockUser)}
                                  className="p-3 bg-white dark:bg-[#151C2C] rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center gap-3 shadow-xs hover:border-indigo-300 dark:hover:border-indigo-800 cursor-pointer transition"
                                >
                                  <div className="relative shrink-0">
                                    <div className="w-11 h-11 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white flex items-center justify-center font-bold text-sm shadow-sm">
                                      {targetUser.displayName[0]}
                                    </div>
                                    {targetUser.isOnline && (
                                      <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                                    )}
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <div className="flex justify-between items-baseline mb-0.5">
                                      <span className="font-bold text-xs text-slate-900 dark:text-white truncate">
                                        {targetUser.displayName}
                                      </span>
                                      <span className="text-[10px] text-slate-400 shrink-0 ml-2">
                                        {conv.time}
                                      </span>
                                    </div>
                                    <div className="flex justify-between items-center">
                                      <p className="text-[11px] text-slate-500 dark:text-slate-400 truncate pr-2">
                                        {conv.lastMessage}
                                      </p>
                                      {conv.unread > 0 && (
                                        <span className="px-1.5 py-0.5 rounded-full bg-[#6366F1] text-white text-[9px] font-bold shrink-0">
                                          {conv.unread}
                                        </span>
                                      )}
                                    </div>
                                  </div>
                                </div>
                              );
                            })}
                          </div>

                          <div className="p-3 bg-indigo-50/50 dark:bg-indigo-950/20 rounded-xl border border-indigo-100 dark:border-indigo-900/30 text-center">
                            <p className="text-[11px] text-indigo-700 dark:text-indigo-300">
                              🔒 Deterministic 1-to-1 chats synced live with Firestore batching.
                            </p>
                          </div>
                        </div>
                      )}

                      {/* TAB 2: EXPLORE FANS */}
                      {activeTab === 'explore' && (
                        <div className="space-y-3">
                          <div className="relative">
                            <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                            <input
                              type="text"
                              value={searchQuery}
                              onChange={(e) => setSearchQuery(e.target.value)}
                              placeholder="Search fans by @handle or name..."
                              className="w-full pl-9 pr-3 py-2.5 bg-white dark:bg-[#151C2C] border border-slate-200 dark:border-slate-800 rounded-xl text-xs focus:outline-none focus:border-[#6366F1] dark:text-white shadow-xs"
                            />
                          </div>

                          <div className="space-y-2 pt-1">
                            <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-1">
                              {searchQuery ? 'Search Results' : 'Suggested Fans'}
                            </div>

                            {filteredUsers.map((user) => (
                              <div
                                key={user.uid}
                                onClick={() => openOtherUserProfile(user)}
                                className="p-3 bg-white dark:bg-[#151C2C] rounded-xl border border-slate-200 dark:border-slate-800 flex items-center gap-3 hover:border-indigo-300 dark:hover:border-indigo-800 transition cursor-pointer shadow-xs"
                              >
                                <div className="relative">
                                  <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-600 text-white font-bold text-xs flex items-center justify-center">
                                    {user.displayName[0]}
                                  </div>
                                  {user.isOnline && (
                                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                                  )}
                                </div>
                                <div className="flex-1 min-w-0">
                                  <div className="font-bold text-xs text-slate-900 dark:text-white truncate">
                                    {user.displayName}
                                  </div>
                                  <div className="text-[11px] text-[#6366F1] font-mono">
                                    @{user.username}
                                  </div>
                                </div>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    openOtherUserProfile(user);
                                  }}
                                  className="px-3 py-1 rounded-lg border border-[#6366F1] text-[#6366F1] hover:bg-indigo-50 dark:hover:bg-indigo-950/40 text-xs font-semibold transition"
                                >
                                  View
                                </button>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* TAB 3: MUTUAL FRIENDS */}
                      {activeTab === 'friends' && (
                        <div className="space-y-3">
                          <div className="text-[11px] font-bold uppercase tracking-wider text-slate-400 px-1">
                            Your Mutual Connections ({otherUsers.slice(0, 2).length})
                          </div>

                          {otherUsers.slice(0, 2).map((user) => (
                            <div
                              key={user.uid}
                              onClick={() => openOtherUserProfile(user)}
                              className="p-3 bg-white dark:bg-[#151C2C] rounded-xl border border-slate-200 dark:border-slate-800 flex items-center gap-3 hover:border-indigo-300 dark:hover:border-indigo-800 transition cursor-pointer shadow-xs"
                            >
                              <div className="relative">
                                <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white font-bold text-xs flex items-center justify-center">
                                  {user.displayName[0]}
                                </div>
                                {user.isOnline && (
                                  <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                                )}
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="font-bold text-xs text-slate-900 dark:text-white truncate">
                                  {user.displayName}
                                </div>
                                <div className="text-[11px] text-[#6366F1] font-mono">
                                  @{user.username}
                                </div>
                              </div>
                              <span className="px-2.5 py-0.5 rounded-full bg-indigo-50 dark:bg-indigo-950/50 text-[#6366F1] text-[10px] font-bold border border-indigo-200 dark:border-indigo-800">
                                Friends
                              </span>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* TAB 4: OWN PROFILE - EXACT STATS: Friends | Followers | Following */}
                      {activeTab === 'profile' && (
                        <div className="space-y-4">
                          <div className="p-5 bg-white dark:bg-[#151C2C] rounded-2xl border border-slate-200 dark:border-slate-800 text-center space-y-3 shadow-xs">
                            <div className="relative inline-block mx-auto">
                              <div className="w-20 h-20 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white font-bold text-2xl flex items-center justify-center shadow-md">
                                {currentUser.displayName[0]}
                              </div>
                              <span className="absolute bottom-0.5 right-0.5 w-4 h-4 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                            </div>

                            <div>
                              <div className="font-extrabold text-base text-slate-900 dark:text-white">
                                {currentUser.displayName}
                              </div>
                              <div className="text-xs text-[#6366F1] font-semibold">
                                @{currentUser.username}
                              </div>
                            </div>

                            {currentUser.bio && (
                              <p className="text-xs text-slate-600 dark:text-slate-400 px-4">
                                {currentUser.bio}
                              </p>
                            )}

                            {/* EXACT ORDER: Friends | Followers | Following */}
                            <div className="grid grid-cols-3 gap-2 py-3 border-t border-b border-slate-100 dark:border-slate-800 text-center">
                              <div>
                                <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                                  {currentUser.friendsCount}
                                </div>
                                <div className="text-[11px] text-slate-500 dark:text-slate-400">Friends</div>
                              </div>
                              <div>
                                <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                                  {currentUser.followersCount}
                                </div>
                                <div className="text-[11px] text-slate-500 dark:text-slate-400">Followers</div>
                              </div>
                              <div>
                                <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                                  {currentUser.followingCount}
                                </div>
                                <div className="text-[11px] text-slate-500 dark:text-slate-400">Following</div>
                              </div>
                            </div>

                            <button
                              onClick={() => showToast('Edit Profile sheet')}
                              className="w-full py-2.5 rounded-xl bg-[#6366F1] text-white text-xs font-semibold shadow hover:opacity-95 transition"
                            >
                              Edit Profile
                            </button>
                          </div>

                          <div className="p-3 bg-white dark:bg-[#151C2C] rounded-xl border border-slate-200 dark:border-slate-800 text-xs text-slate-500 flex items-center justify-between">
                            <span>Settings available in top-right header</span>
                            <Settings className="w-4 h-4 text-[#6366F1]" />
                          </div>
                        </div>
                      )}

                    </div>

                    {/* Bottom Navigation Bar */}
                    <div className="p-2 bg-white dark:bg-[#151C2C] border-t border-slate-200 dark:border-slate-800 grid grid-cols-4 gap-1">
                      <button
                        onClick={() => setActiveTab('chats')}
                        className={`p-2 rounded-xl text-center flex flex-col items-center gap-1 transition ${
                          activeTab === 'chats' ? 'text-[#6366F1]' : 'text-slate-400'
                        }`}
                      >
                        <MessageSquare className="w-4 h-4" />
                        <span className="text-[10px] font-semibold">Chats</span>
                      </button>
                      <button
                        onClick={() => setActiveTab('explore')}
                        className={`p-2 rounded-xl text-center flex flex-col items-center gap-1 transition ${
                          activeTab === 'explore' ? 'text-[#6366F1]' : 'text-slate-400'
                        }`}
                      >
                        <Search className="w-4 h-4" />
                        <span className="text-[10px] font-semibold">Explore</span>
                      </button>
                      <button
                        onClick={() => setActiveTab('friends')}
                        className={`p-2 rounded-xl text-center flex flex-col items-center gap-1 transition ${
                          activeTab === 'friends' ? 'text-[#6366F1]' : 'text-slate-400'
                        }`}
                      >
                        <Users className="w-4 h-4" />
                        <span className="text-[10px] font-semibold">Friends</span>
                      </button>
                      <button
                        onClick={() => setActiveTab('profile')}
                        className={`p-2 rounded-xl text-center flex flex-col items-center gap-1 transition ${
                          activeTab === 'profile' ? 'text-[#6366F1]' : 'text-slate-400'
                        }`}
                      >
                        <User className="w-4 h-4" />
                        <span className="text-[10px] font-semibold">Profile</span>
                      </button>
                    </div>

                  </div>
                )}

                {/* OTHER USER PROFILE MODAL / SHEET */}
                {selectedOtherUser && (
                  <div className="absolute inset-0 bg-black/60 z-50 flex flex-col justify-end animate-fade-in">
                    <div 
                      className="bg-white dark:bg-[#151C2C] rounded-t-3xl border-t border-slate-200 dark:border-slate-800 p-5 space-y-4 shadow-2xl relative"
                      onClick={(e) => e.stopPropagation()}
                    >
                      {/* Top Handle / Drag Bar */}
                      <div className="w-10 h-1 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto" />

                      {/* Header Actions: [X] Close button & [⋮] More Menu */}
                      <div className="flex items-center justify-between">
                        <button
                          onClick={() => setSelectedOtherUser(null)}
                          className="p-1.5 rounded-full text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                          title="Close"
                        >
                          <X className="w-5 h-5" />
                        </button>

                        <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                          Profile
                        </span>

                        <div className="relative">
                          <button
                            onClick={() => setShowMoreMenu(!showMoreMenu)}
                            className="p-1.5 rounded-full text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                            title="More options"
                          >
                            <MoreVertical className="w-5 h-5" />
                          </button>

                          {/* [⋮] MORE POPUP MENU */}
                          {showMoreMenu && (
                            <div className="absolute right-0 top-8 w-48 bg-white dark:bg-[#0B0F19] rounded-xl border border-slate-200 dark:border-slate-800 shadow-xl py-1.5 z-50 text-xs animate-scale-in">
                              <button
                                onClick={() => {
                                  setShowMoreMenu(false);
                                  showToast(`Copied https://heyfans.app/u/@${selectedOtherUser.username}`);
                                }}
                                className="w-full px-3 py-2 text-left flex items-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-700 dark:text-slate-300"
                              >
                                <Share2 className="w-4 h-4 text-[#6366F1]" />
                                Share Profile Link
                              </button>
                              <button
                                onClick={() => {
                                  setShowMoreMenu(false);
                                  showToast(`Reported @${selectedOtherUser.username}. Thank you.`);
                                }}
                                className="w-full px-3 py-2 text-left flex items-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-amber-600 dark:text-amber-400"
                              >
                                <Flag className="w-4 h-4" />
                                Report User
                              </button>
                              <button
                                onClick={() => {
                                  setShowMoreMenu(false);
                                  setSelectedOtherUser(null);
                                  showToast(`Blocked @${selectedOtherUser.username}`);
                                }}
                                className="w-full px-3 py-2 text-left flex items-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-rose-600 dark:text-rose-400"
                              >
                                <Ban className="w-4 h-4" />
                                Block User
                              </button>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* User Info */}
                      <div className="text-center space-y-2 pt-1">
                        <div className="relative inline-block mx-auto">
                          <div className="w-18 h-18 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-600 text-white font-bold text-2xl flex items-center justify-center shadow-md">
                            {selectedOtherUser.displayName[0]}
                          </div>
                          {selectedOtherUser.isOnline && (
                            <span className="absolute bottom-0.5 right-0.5 w-3.5 h-3.5 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                          )}
                        </div>

                        <div>
                          <h3 className="font-extrabold text-lg text-slate-900 dark:text-white">
                            {selectedOtherUser.displayName}
                          </h3>
                          <div className="text-xs font-mono font-semibold text-[#6366F1]">
                            @{selectedOtherUser.username}
                          </div>
                        </div>

                        {/* Joined Date */}
                        <div className="flex items-center justify-center gap-1.5 text-[11px] text-slate-400">
                          <Calendar className="w-3.5 h-3.5" />
                          <span>Joined {selectedOtherUser.joinedDate}</span>
                        </div>

                        {selectedOtherUser.bio && (
                          <p className="text-xs text-slate-600 dark:text-slate-300 pt-1 px-4 leading-relaxed">
                            {selectedOtherUser.bio}
                          </p>
                        )}
                      </div>

                      {/* STATS: Friends | Followers | Following */}
                      <div className="grid grid-cols-3 gap-2 py-3 px-2 bg-slate-50 dark:bg-[#0B0F19] rounded-xl border border-slate-200 dark:border-slate-800 text-center">
                        <div>
                          <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                            {selectedOtherUser.friendsCount}
                          </div>
                          <div className="text-[10px] text-slate-500 dark:text-slate-400">Friends</div>
                        </div>
                        <div>
                          <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                            {selectedOtherUser.followersCount}
                          </div>
                          <div className="text-[10px] text-slate-500 dark:text-slate-400">Followers</div>
                        </div>
                        <div>
                          <div className="font-extrabold text-sm text-slate-900 dark:text-white">
                            {selectedOtherUser.followingCount}
                          </div>
                          <div className="text-[10px] text-slate-500 dark:text-slate-400">Following</div>
                        </div>
                      </div>

                      {/* BOTTOM ACTIONS: [ Message ] and [ Follow ] MUST HAVE EQUAL WIDTH/SIZE */}
                      <div className="grid grid-cols-2 gap-3 pt-2">
                        {/* [ Message ] Button */}
                        <button
                          onClick={() => {
                            openChatWithUser(selectedOtherUser);
                          }}
                          className="w-full py-3 rounded-xl border-2 border-[#6366F1] text-[#6366F1] hover:bg-indigo-50 dark:hover:bg-indigo-950/40 font-bold text-xs flex items-center justify-center gap-2 transition"
                        >
                          <Send className="w-4 h-4" />
                          <span>Message</span>
                        </button>

                        {/* [ Follow / Following ] Button */}
                        <button
                          onClick={toggleFollowUser}
                          className={`w-full py-3 rounded-xl font-bold text-xs flex items-center justify-center gap-2 transition shadow-sm ${
                            isFollowingSelected
                              ? 'bg-slate-200 dark:bg-slate-800 text-slate-800 dark:text-slate-200'
                              : 'bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white shadow-indigo-500/20'
                          }`}
                        >
                          {isFollowingSelected ? (
                            <>
                              <Check className="w-4 h-4 text-emerald-500" />
                              <span>Following</span>
                            </>
                          ) : (
                            <>
                              <UserPlus className="w-4 h-4" />
                              <span>Follow</span>
                            </>
                          )}
                        </button>
                      </div>

                    </div>
                  </div>
                )}

                {/* SETTINGS SCREEN MODAL (ACCESSIBLE ONLY FROM OWN PROFILE) */}
                {showSettingsModal && currentUser && (
                  <div className="absolute inset-0 bg-white dark:bg-[#0B0F19] z-50 flex flex-col animate-fade-in">
                    <div className="p-4 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => setShowSettingsModal(false)}
                          className="p-1 rounded-lg text-[#6366F1] font-bold text-xs"
                        >
                          ← Back
                        </button>
                        <h3 className="font-bold text-sm text-slate-900 dark:text-white">
                          Account Settings
                        </h3>
                      </div>
                      <span className="text-[10px] text-slate-400">Hey Fans v1.0</span>
                    </div>

                    <div className="flex-1 p-4 space-y-4 overflow-y-auto">
                      {/* Account Summary Card */}
                      <div className="p-4 bg-slate-50 dark:bg-[#151C2C] rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center gap-3">
                        <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white font-bold text-base flex items-center justify-center">
                          {currentUser.displayName[0]}
                        </div>
                        <div className="min-w-0 flex-1">
                          <div className="font-bold text-xs text-slate-900 dark:text-white truncate">
                            {currentUser.displayName}
                          </div>
                          <div className="text-[11px] text-[#6366F1] font-mono">
                            @{currentUser.username}
                          </div>
                          <div className="text-[10px] text-slate-400 truncate">
                            {currentUser.email}
                          </div>
                        </div>
                      </div>

                      {/* Options */}
                      <div className="space-y-2">
                        <div className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs">
                          <span className="text-slate-700 dark:text-slate-300">Push Notifications</span>
                          <span className="text-emerald-500 font-semibold">Enabled</span>
                        </div>
                        <div className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs">
                          <span className="text-slate-700 dark:text-slate-300">Privacy & Security</span>
                          <ChevronRight className="w-4 h-4 text-slate-400" />
                        </div>
                        <div className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs">
                          <span className="text-slate-700 dark:text-slate-300">Community Guidelines</span>
                          <ChevronRight className="w-4 h-4 text-slate-400" />
                        </div>
                      </div>

                      {/* Logout Action */}
                      <button
                        onClick={handleLogout}
                        className="w-full mt-4 py-3 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 border border-rose-200 dark:border-rose-900/50 font-bold text-xs transition flex items-center justify-center gap-2"
                      >
                        <LogOut className="w-4 h-4" />
                        <span>Sign Out of Hey Fans</span>
                      </button>
                    </div>
                  </div>
                )}

                {/* IN-APP ACTIVITY & NOTIFICATIONS MODAL */}
                {showNotificationsModal && currentUser && (
                  <div className="absolute inset-0 bg-white dark:bg-[#0B0F19] z-50 flex flex-col animate-fade-in">
                    {/* Top Bar */}
                    <div className="p-3.5 bg-white dark:bg-[#151C2C] border-b border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-xs">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => setShowNotificationsModal(false)}
                          className="p-1.5 -ml-1 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                          title="Back"
                        >
                          <ArrowLeft className="w-5 h-5" />
                        </button>
                        <h3 className="font-bold text-sm text-slate-900 dark:text-white">
                          Activity & Notifications
                        </h3>
                      </div>
                      <div className="flex items-center gap-1">
                        {notifications.some(n => !n.isRead) && (
                          <button
                            onClick={() => {
                              setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
                              showToast('All activity marked as read');
                            }}
                            className="text-[11px] font-semibold text-[#6366F1] px-2 py-1 rounded-lg hover:bg-indigo-50 dark:hover:bg-indigo-950/40 transition"
                          >
                            Mark All Read
                          </button>
                        )}
                        <button
                          onClick={() => setShowNotificationsModal(false)}
                          className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {/* Filter Tabs */}
                    <div className="flex border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-[#151C2C]">
                      <button
                        onClick={() => setNotificationFilter('all')}
                        className={`flex-1 py-2.5 text-xs font-bold transition border-b-2 ${
                          notificationFilter === 'all'
                            ? 'border-[#6366F1] text-[#6366F1]'
                            : 'border-transparent text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
                        }`}
                      >
                        All Activity ({notifications.length})
                      </button>
                      <button
                        onClick={() => setNotificationFilter('unread')}
                        className={`flex-1 py-2.5 text-xs font-bold transition border-b-2 ${
                          notificationFilter === 'unread'
                            ? 'border-[#6366F1] text-[#6366F1]'
                            : 'border-transparent text-slate-400 hover:text-slate-600 dark:hover:text-slate-200'
                        }`}
                      >
                        Unread ({notifications.filter(n => !n.isRead).length})
                      </button>
                    </div>

                    {/* Notifications List */}
                    <div className="flex-1 p-3.5 space-y-2.5 overflow-y-auto bg-slate-50 dark:bg-[#0B0F19]">
                      {notifications
                        .filter(n => notificationFilter === 'all' || !n.isRead)
                        .length === 0 ? (
                        <div className="text-center py-16 space-y-3">
                          <div className="w-14 h-14 rounded-full bg-indigo-50 dark:bg-indigo-950/40 text-[#6366F1] flex items-center justify-center mx-auto">
                            <Bell className="w-6 h-6" />
                          </div>
                          <div className="font-bold text-sm text-slate-800 dark:text-slate-200">
                            {notificationFilter === 'unread' ? 'All Caught Up! 🎉' : 'No Activity Yet'}
                          </div>
                          <p className="text-xs text-slate-400 max-w-[240px] mx-auto leading-relaxed">
                            {notificationFilter === 'unread'
                              ? 'You have zero unread notifications.'
                              : 'When fans follow you, send messages, or invite you to group circles, you’ll see them here.'}
                          </p>
                        </div>
                      ) : (
                        notifications
                          .filter(n => notificationFilter === 'all' || !n.isRead)
                          .map((notif) => {
                            const isUnread = !notif.isRead;
                            return (
                              <div
                                key={notif.id}
                                onClick={() => {
                                  // Mark as read
                                  setNotifications(prev =>
                                    prev.map(n => (n.id === notif.id ? { ...n, isRead: true } : n))
                                  );
                                  // Context action
                                  if (notif.senderId) {
                                    const targetUser = otherUsers.find(u => u.uid === notif.senderId);
                                    if (targetUser) {
                                      setShowNotificationsModal(false);
                                      if (notif.type === 'chat_message') {
                                        openChatWithUser(targetUser);
                                      } else {
                                        openOtherUserProfile(targetUser);
                                      }
                                    }
                                  }
                                }}
                                className={`p-3 rounded-2xl border transition cursor-pointer flex items-start gap-3 ${
                                  isUnread
                                    ? 'bg-indigo-50/60 dark:bg-indigo-950/25 border-indigo-200 dark:border-indigo-800/60 shadow-xs'
                                    : 'bg-white dark:bg-[#151C2C] border-slate-200 dark:border-slate-800'
                                }`}
                              >
                                <div className="relative shrink-0 mt-0.5">
                                  <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white flex items-center justify-center font-bold text-xs shadow-xs">
                                    {notif.senderName ? notif.senderName[0] : 'H'}
                                  </div>
                                  <div
                                    className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full flex items-center justify-center text-[9px] text-white border-2 border-white dark:border-[#151C2C] ${
                                      notif.type === 'new_follower'
                                        ? 'bg-[#6366F1]'
                                        : notif.type === 'mutual_friend'
                                        ? 'bg-[#EC4899]'
                                        : notif.type === 'group_invitation'
                                        ? 'bg-amber-500'
                                        : 'bg-[#6366F1]'
                                    }`}
                                  >
                                    {notif.type === 'new_follower' && <UserPlus className="w-2.5 h-2.5" />}
                                    {notif.type === 'mutual_friend' && <Sparkles className="w-2.5 h-2.5" />}
                                    {notif.type === 'group_invitation' && <Users className="w-2.5 h-2.5" />}
                                    {notif.type === 'chat_message' && <MessageSquare className="w-2.5 h-2.5" />}
                                  </div>
                                </div>

                                <div className="flex-1 min-w-0">
                                  <div className="flex items-baseline justify-between mb-0.5">
                                    <span
                                      className={`text-xs truncate ${
                                        isUnread
                                          ? 'font-bold text-slate-900 dark:text-white'
                                          : 'font-semibold text-slate-700 dark:text-slate-300'
                                      }`}
                                    >
                                      {notif.title}
                                    </span>
                                    <span className="text-[10px] text-slate-400 shrink-0 ml-2">
                                      {notif.time}
                                    </span>
                                  </div>
                                  <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-snug line-clamp-2">
                                    {notif.message}
                                  </p>
                                </div>

                                {isUnread && (
                                  <div className="w-2 h-2 rounded-full bg-[#6366F1] shrink-0 mt-2" />
                                )}
                              </div>
                            );
                          })
                      )}
                    </div>

                    {/* Footer Actions */}
                    <div className="p-3 bg-white dark:bg-[#151C2C] border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                      <button
                        onClick={() => {
                          setNotifications([]);
                          showToast('All notifications cleared');
                        }}
                        className="text-[11px] font-semibold text-rose-500 hover:underline"
                      >
                        Clear All Activity
                      </button>
                      <button
                        onClick={() => setShowNotificationsModal(false)}
                        className="px-4 py-1.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-xs font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-200 transition"
                      >
                        Close
                      </button>
                    </div>
                  </div>
                )}

                {/* 1-TO-1 DIRECT CHAT SCREEN */}
                {activeChatUser && currentUser && (
                  <div className="absolute inset-0 bg-white dark:bg-[#0B0F19] z-50 flex flex-col animate-fade-in">
                    
                    {/* Chat App Bar */}
                    <div className="p-3.5 bg-white dark:bg-[#151C2C] border-b border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-xs">
                      <div className="flex items-center gap-2.5 min-w-0">
                        <button
                          onClick={() => setActiveChatUser(null)}
                          className="p-1.5 -ml-1 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                          title="Back"
                        >
                          <ArrowLeft className="w-5 h-5" />
                        </button>
                        
                        <div className="relative shrink-0">
                          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-[#6366F1] to-[#EC4899] text-white font-bold text-xs flex items-center justify-center shadow-xs">
                            {activeChatUser.displayName[0]}
                          </div>
                          {activeChatUser.isOnline && (
                            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-white dark:border-[#151C2C] rounded-full" />
                          )}
                        </div>

                        <div className="min-w-0 flex-1">
                          <div className="font-bold text-xs text-slate-900 dark:text-white truncate">
                            {activeChatUser.displayName}
                          </div>
                          <div className="text-[10px] text-[#6366F1] font-mono flex items-center gap-1">
                            <span>@{activeChatUser.username}</span>
                            <span className="text-slate-400">•</span>
                            <span className="text-emerald-500 font-sans font-semibold">
                              {activeChatUser.isOnline ? 'Active now' : 'Offline'}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-1">
                        <button 
                          onClick={() => showToast(`1-to-1 conversation with @${activeChatUser.username}`)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                        >
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {/* Messages Scroll Area */}
                    <div className="flex-1 p-3.5 space-y-3 overflow-y-auto bg-slate-50/70 dark:bg-[#0B0F19]">
                      <div className="text-center my-2">
                        <span className="px-3 py-1 bg-slate-200/60 dark:bg-slate-800/80 text-slate-500 dark:text-slate-400 rounded-full text-[10px] font-semibold">
                          Messages are end-to-end synced
                        </span>
                      </div>

                      {(messagesMap[activeChatUser.uid] || []).map((msg) => {
                        const isMe = msg.senderId === 'current' || msg.senderId === currentUser.uid;

                        return (
                          <div
                            key={msg.id}
                            className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}
                          >
                            <div
                              className={`p-3 max-w-[82%] text-xs leading-relaxed ${
                                isMe
                                  ? 'bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white rounded-2xl rounded-tr-xs shadow-sm shadow-indigo-500/20'
                                  : 'bg-white dark:bg-[#151C2C] border border-slate-200 dark:border-slate-800 text-slate-900 dark:text-slate-100 rounded-2xl rounded-tl-xs shadow-xs'
                              }`}
                            >
                              <p className="break-words">{msg.text}</p>
                              
                              <div
                                className={`text-[9px] flex items-center justify-end gap-1 mt-1 ${
                                  isMe ? 'text-indigo-100' : 'text-slate-400'
                                }`}
                              >
                                <span>{msg.time}</span>
                                {isMe && (
                                  <CheckCheck className={`w-3 h-3 ${msg.isRead ? 'text-indigo-200' : 'text-indigo-300/70'}`} />
                                )}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {/* Message Input Bottom Bar */}
                    <form
                      onSubmit={sendChatMessage}
                      className="p-2.5 bg-white dark:bg-[#151C2C] border-t border-slate-200 dark:border-slate-800 flex items-center gap-2"
                    >
                      <button
                        type="button"
                        onClick={() => showToast('Image picker attached (StorageService ready)')}
                        className="p-2 rounded-xl text-slate-400 hover:text-[#6366F1] hover:bg-slate-100 dark:hover:bg-slate-800 transition shrink-0"
                        title="Attach image"
                      >
                        <ImageIcon className="w-5 h-5" />
                      </button>

                      <input
                        type="text"
                        value={chatInputText}
                        onChange={(e) => setChatInputText(e.target.value)}
                        placeholder={`Message @${activeChatUser.username}...`}
                        className="flex-1 px-3.5 py-2 bg-slate-100 dark:bg-[#0B0F19] border border-slate-200 dark:border-slate-800 rounded-xl text-xs focus:outline-none focus:border-[#6366F1] dark:text-white"
                      />

                      <button
                        type="submit"
                        disabled={!chatInputText.trim()}
                        className="w-9 h-9 rounded-xl bg-gradient-to-r from-[#6366F1] to-[#4F46E5] text-white flex items-center justify-center shrink-0 shadow-sm shadow-indigo-500/25 disabled:opacity-40 disabled:cursor-not-allowed hover:opacity-95 transition"
                      >
                        <Send className="w-4 h-4" />
                      </button>
                    </form>

                  </div>
                )}

              </div>

              {/* Bottom Home Indicator */}
              <div className="w-full pb-2 pt-1 flex justify-center bg-transparent">
                <div className="w-32 h-1 bg-slate-400/40 rounded-full" />
              </div>
            </div>
          )}

          {/* Dart Code Tab */}
          {activeViewTab === 'code' && (
            <div className="w-full bg-white dark:bg-[#151C2C] p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
              <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                <FileCode2 className="w-4 h-4 text-[#6366F1]" />
                Hey Fans Clean Architecture Codebase
              </h3>
              <div className="bg-slate-900 text-slate-200 p-4 rounded-xl font-mono text-xs overflow-x-auto space-y-2">
                <div>📁 <span className="text-indigo-400 font-bold">lib/</span></div>
                <div className="pl-4">📄 main.dart <span className="text-slate-500">// Firebase init & MultiProvider</span></div>
                <div className="pl-4">📁 <span className="text-indigo-300">app/</span></div>
                <div className="pl-8">📄 routes.dart <span className="text-slate-500">// Splash, Login, Register, Home, Settings</span></div>
                <div className="pl-8">📄 theme.dart <span className="text-slate-500">// HeyTheme (#6366F1, #4F46E5, #EC4899)</span></div>
                <div className="pl-8">📄 constants.dart <span className="text-slate-500">// Collections: users, followers, following, friends</span></div>
                <div className="pl-4">📁 <span className="text-indigo-300">models/</span></div>
                <div className="pl-8">📄 user_model.dart <span className="text-emerald-400 font-bold">// friendsCount, followersCount, followingCount</span></div>
                <div className="pl-4">📁 <span className="text-indigo-300">services/</span></div>
                <div className="pl-8">📄 auth_service.dart <span className="text-emerald-400 font-bold">// Firebase Auth & handle check</span></div>
                <div className="pl-8">📄 firestore_service.dart <span className="text-emerald-400">// /users CRUD, follow toggle, report, block</span></div>
                <div className="pl-4">📁 <span className="text-indigo-300">providers/</span></div>
                <div className="pl-8">📄 auth_provider.dart <span className="text-emerald-400 font-bold">// Reactive State & Errors</span></div>
                <div className="pl-4">📁 <span className="text-indigo-300">screens/</span></div>
                <div className="pl-8">📁 profile/</div>
                <div className="pl-12">📄 user_profile_modal.dart <span className="text-emerald-400 font-bold">// [X] Close, [⋮] More, Equal [Message][Follow]</span></div>
                <div className="pl-8">📁 home/tabs/</div>
                <div className="pl-12">📄 profile_tab.dart <span className="text-emerald-400 font-bold">// Settings on own profile ONLY. Stats: Friends | Followers | Following</span></div>
                <div className="pl-12">📄 explore_tab.dart <span className="text-slate-300">// Search & launch profile modal</span></div>
                <div className="pl-12">📄 friends_tab.dart <span className="text-slate-300">// Mutual friends list</span></div>
                <div className="pl-12">📄 chats_tab.dart <span className="text-slate-300">// Messages</span></div>
                <div className="pl-8">📁 settings/</div>
                <div className="pl-12">📄 settings_screen.dart <span className="text-slate-300">// Sign out modal & account info</span></div>
              </div>
            </div>
          )}

          {/* Security Rules Tab */}
          {activeViewTab === 'rules' && (
            <div className="w-full bg-white dark:bg-[#151C2C] p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
              <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-emerald-500" />
                Firestore Security Rules
              </h3>
              <div className="bg-slate-900 text-emerald-400 p-4 rounded-xl font-mono text-xs overflow-x-auto leading-relaxed">
                <pre>{`rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      
      match /following/{targetUid} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /followers/{followerUid} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == followerUid;
      }
      
      match /blocks/{blockedUid} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /reports/{reportId} {
      allow create: if request.auth != null;
      allow read: if false; // Admin only
    }
  }
}`}</pre>
              </div>
            </div>
          )}
        </div>

      </main>
    </div>
  );
}
