const userService = require('../services/user.service');
const logService = require('../services/log.service');

const registerUser = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;
    const { accessToken, refreshToken, userJson: user, verifyToken } = await userService.registerUser({ email, password, name });

    res.cookie('accessToken', accessToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'None',
    });
    res.cookie('refreshToken', refreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'None',
      maxAge: 60 * 60 * 1000,
    });

    res.status(201).json({
      message: 'User registered successfully!',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        isVerified: user.is_verified,
      },
      verifyToken: verifyToken,
    });
  } catch (error) {
    next(error);
  }
};

const loginUser = async (req, res, next) => {
  try {
    const { identifier, password } = req.body;
    const { user, accessToken, refreshToken } = await userService.loginUser({
      identifier,
      password,
    });

    res.cookie('accessToken', accessToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'None',
    });
    res.cookie('refreshToken', refreshToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'None',
      maxAge: 60 * 60 * 1000,
    });

    res.status(200).json({
      message: 'Login successful!',
      curUser: {
        id: user.id,
        name: user.name,
        email: user.email,
        isVerified: user.is_verified,
      },
    });

    // Manual Log for Login
    await logService.createLog({
      userId: user.id,
      action: 'LOGIN',
      details: 'User logged in successfully',
      entity: 'User',
      entityId: user.id
    });
  } catch (error) {
    next(error);
  }
};

const logoutUser = async (req, res, next) => {
  try {
    res.clearCookie('accessToken');
    res.clearCookie('refreshToken');
    // Manual Log for Logout (Try to get userId from req.user if available, otherwise rely on context or null)
    // Note: logout route might not be protected, so req.user might be undefined.
    // If you want to guarantee logging user on logout, ensure the route is protected.
    if (req.user && req.user.id) {
      await logService.createLog({
        userId: req.user.id,
        action: 'LOGOUT',
        details: 'User logged out',
        entity: 'User',
        entityId: req.user.id
      });
    }

    res.status(200).json({ message: 'Logout successful!' });
  } catch (error) {
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.cookies;
    if (!refreshToken) {
      return res.status(401).json({ message: 'Refresh token not found' });
    }

    const newAccessToken = await userService.refreshToken(refreshToken);

    res.cookie('accessToken', newAccessToken, {
      httpOnly: true,
      secure: true,
      sameSite: 'None',
    });

    res.status(200).json({ message: 'Access token refreshed successfully' });
  } catch (error) {
    next(error);
  }
};

const sendVerificationCode = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }
    const result = await userService.sendVerificationCode(email);

    // Attempt to log verification code sent. 
    // Since this might not be authenticated, check for user existence first or just log if possible.
    // However, sendVerificationCode takes an email. We can try to find the user by email to associate the log.
    // BUT optimize: userService.sendVerificationCode already finds the user. 
    // Maybe better to return user info from service or just find it here?
    // Let's keep it simple: if we can find the user, log it. But userService throws if it's already verified?
    // Actually, sendVerificationCode is for registration verification mostly? No, also potentially for password reset?
    // Let's actually look at user.service again. It checks if user exists.

    // For now, let's just log if there is a current user (e.g. resending code while logged in?), or skip if anonymous.
    // If it's registration, user might not exist yet? Wait, sendVerificationCode checks existingUser.

    // Actually, looking at user.service:81, it finds user.
    // Let's just SKIP logging "Verification Code Sent" for now to avoid complexity of looking up user again here.
    // Or we can ask user if they want this logged.

    res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({ message: error.message });
    }
    next(error);
  }
};

const getUser = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    }

    const user = await userService.getUser(req.user.id);
    res.status(200).json({ user });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

// TODO rewrite this
const deleteUser = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    }

    const result = await userService.deleteUser(req.user.id);
    res.status(200).json(result);
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};


const verifyEmail = async (req, res, next) => {
  try {
    const { code, token } = req.body;
    const result = await userService.verifyEmail(code, token);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const changeUserPassword = async (req, res, next) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    }

    const result = await userService.changeUserPassword(req.user.id, oldPassword, newPassword);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const editUser = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized: User ID missing' });
    }

    const { name, gender, email } = req.body;
    let { imageUrl } = req.body;

    if (req.file) {
      imageUrl = req.file.path;
    }

    const updateData = {
      name,
      gender,
      email,
      imageUrl
    };

    // Remove undefined fields
    Object.keys(updateData).forEach(key => updateData[key] === undefined && delete updateData[key]);

    const result = await userService.updateUser(req.user.id, updateData);
    res.status(200).json(result);
  } catch (error) {
    // If it's a validation error (like duplicate email), we might want 400 or 409
    if (error.message.includes('already exists')) {
      return res.status(409).json({ message: error.message });
    }
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  registerUser,
  loginUser,
  logoutUser,
  refreshToken,
  sendVerificationCode,
  getUser,
  deleteUser,
  verifyEmail,
  changeUserPassword,
  editUser,
};
