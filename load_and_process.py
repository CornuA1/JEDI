"""
load JEDI data and do basic analysis

@author: Lukas Fischer

"""

import sys, yaml, os
with open('.' + os.sep + 'loc_settings.yaml', 'r') as f:
    loc_info = yaml.load(f)
sys.path.append(loc_info['base_dir'])
# import warnings; warnings.simplefilter('ignore')

import ipdb
import numpy as np
import scipy.io as sio
from scipy.optimize import curve_fit
from matplotlib import pyplot as plt
from sklearn import linear_model
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import PolynomialFeatures

from dF_win import dF_win

def bleach_decay(t, tau_slow, amp_slow, b_slow, tau_fast, amp_fast, b_fast):
    """ bi-exponential decay function to fit. Mind you slow and fast don't have to necessarily correspond to how scipy fits the parameters """
    return (amp_slow * np.exp(-t/tau_slow)) + (amp_fast * np.exp(-t/tau_fast))

def exp_decay_func(x, a, k, b):
    """ exponential decay function """
    return a * np.exp(-k*x) + b

def linear_decay_func(x, a, b):
    """ linear decay function """
    return -(a*x) + b

def test_bleaching_function():
    tau_slow = 5
    tau_fast = 1
    amp_slow = 1
    amp_fast = 2
    x = np.linspace(0,10,10000)
    y_slow = amp_slow * np.exp(-x/tau_slow)
    y_fast = amp_fast * np.exp(-x/tau_fast)
    y_comb = amp_slow * np.exp(-x/tau_slow) + amp_fast * np.exp(-x/tau_fast)
    y_test = bleach_decay(x, tau_fast, amp_fast, 5)
    plt.figure()
    ax1 = plt.subplot(111)
    plt.plot(x,y_comb, label='amp_slow * np.exp(-x/tau_slow) + amp_fast * np.exp(-x/tau_fast)')
    plt.plot(x,y_slow, label='amp_slow * np.exp(-x/tau_slow)')
    plt.plot(x,y_fast, label='amp_fast * np.exp(-x/tau_fast)')
    plt.plot(x,y_test, label='y test')
    plt.legend()
    plt.show()

def fit_bleaching():

    CROP_FRAMES = 15
    ROI = 0

    # specify file to load
    sig_folder = 'F:\\20200224\\M01\\'
    sig_file = 'M01_000_022'
    fs = 991.25 # Hz

    # load data from sigfile
    raw_sig_mat = np.genfromtxt( sig_folder + sig_file + '.sig', delimiter=',' )
    raw_sig_mat = raw_sig_mat[CROP_FRAMES:1500,:]

    # load metadata. -1 in CROP because for some reason there is a difference of one datapoint
    rec_info = sio.loadmat( sig_folder + sig_file + '.extra', appendmat=False)
    frame_brightness = rec_info['meanBrightness'].T[CROP_FRAMES:1500]

    # timestampe are not accurate for very fast recordings so we make our own based on the sampling frequency
    # ts = rec_info['timestamps'].T[CROP_FRAMES:-1]

    # ipdb.set_trace()
    ts = np.arange(0,raw_sig_mat.shape[0]*(1/fs),1/fs)

    # offset trace for curve fitting
    zero_offset = np.nanmean(raw_sig_mat[-500:,ROI])
    raw_sig_mat[:,ROI] = raw_sig_mat[:,ROI] - zero_offset


    popt, pcov = curve_fit(exp_decay_func, np.squeeze(ts), raw_sig_mat[:,ROI], maxfev=2000)
    a, k, b = popt
    fit_line_data_exp = exp_decay_func(np.squeeze(ts), a, k, b)


    # ipdb.set_trace()
    # set bounds for initial parameter space
    b_bounds = [np.amin(raw_sig_mat[:,ROI]), np.amax(raw_sig_mat[:,ROI])]
    print(b_bounds)
    tau_bounds = [0,5.0]
    amp_bounds = [np.amin(raw_sig_mat[:,ROI]), np.amax(raw_sig_mat[:,ROI])]
    popt, pcov = curve_fit(bleach_decay, ts, raw_sig_mat[:,ROI],
                    bounds=([tau_bounds[0],amp_bounds[0],b_bounds[0],tau_bounds[0],amp_bounds[0],b_bounds[0]],
                            [tau_bounds[1],amp_bounds[1],b_bounds[1],tau_bounds[1],amp_bounds[1],b_bounds[1]]), maxfev=2000)
    tau_slow, amp_slow, b_slow, tau_fast, amp_fast, b_fast = popt
    print('tau_slow: ' + str(tau_slow))
    print('amp_slow: ' + str(amp_slow))
    print('offset_slow: ' + str(b_slow))
    print('tau_fast: ' + str(tau_fast))
    print('amp_fast: ' + str(amp_fast))
    print('offset_fast: ' + str(b_fast))
    fit_line_bleach = bleach_decay( ts, tau_slow, amp_slow, b_slow, tau_fast, amp_fast, b_fast)

    # correct baseline
    baseline_drift = fit_line_bleach
    baseline_reference = fit_line_bleach[0]
    baseline_offset = baseline_drift - baseline_reference
    adjusted_sig = raw_sig_mat[:,ROI] - baseline_offset

    # calculate dF_F
    dff = (adjusted_sig - np.mean(adjusted_sig))/np.mean(adjusted_sig)
    # sig_z = (adjusted_sig - np.mean(adjusted_sig)) / np.std(adjusted_sig)
    std_thresh = 3 * np.std(dff)

    plt.figure()
    ax1 = plt.subplot(311)
    plt.plot(ts,raw_sig_mat[:,ROI], c='0.5')
    plt.ylabel('Brightness (a.u.)')
    # plt.plot(ts,pipeline.predict(ts), c='r', lw=2)
    # plt.plot(ts,p(ts), c='0.5', lw=2, ls='--')
    # plt.plot(ts,fit_line_data_lin, c='g', lw=2, ls='--')
    # plt.plot(ts,fit_line_data_exp, c='r', lw=2, ls='--')
    plt.plot(ts,fit_line_bleach, c='r', lw=2, ls='--')
    plt.subplot(312, sharex=ax1)
    plt.plot(ts,adjusted_sig, c='k')
    plt.ylabel('Brightness (a.u.)')
    plt.xlabel('time (sec.)')
    plt.subplot(313, sharex=ax1)
    plt.plot(ts,-dff, c='k')
    plt.plot(ts,np.zeros((ts.shape[0],)), c='0.5', lw=2, ls='--')
    plt.axhspan(0-std_thresh, 0+std_thresh, color='0.8',alpha=0.5)
    plt.ylabel('dF/F')
    plt.xlabel('time (sec.)')
    # plt.subplot(413)
    # plt.scatter(x,y,c='none', edgecolor='0.5')
    # plt.plot(x,fit_line, c='g', lw=2, ls='--')
    # plt.subplot(414)
    # plt.scatter(x,y2,c='none', edgecolor='0.5')
    # plt.plot(x,fit_line2, c='g', lw=2, ls='--')
    plt.xlim([0,5])
    plt.show()

    # fit bleaching
    # polynomial_features = PolynomialFeatures(degree=2, include_bias=False)
    # reg = linear_model.LinearRegression()
    # pipeline = Pipeline([("polynomial_features", polynomial_features), ("linear_regression", reg)])
    # pipeline.fit(ts,raw_sig_mat[:,ROI])

    # x = np.linspace(0,1000,1000)
    # y = linear_decay_func(x, 0.1, 100) + (np.random.ranf(1000) * 30)
    # popt, pcov = curve_fit(linear_decay_func, x, y)
    # a, b = popt
    # fit_line = linear_decay_func(x, a, b)
    #
    # y2 = exp_decay_func(x, 100, 0.005, 0) + (np.random.ranf(1000) * 30)
    # popt, pcov = curve_fit(exp_decay_func, x, y2)
    # a, k, b = popt
    # fit_line2 = exp_decay_func(x, a, k, b)
    # ipdb.set_trace()

    # curve fit
    # z = np.polyfit(ts,raw_sig_mat[:,ROI],2)
    # p = np.poly1d(z)

    # ipdb.set_trace()

    # ipdb.set_trace()
    # popt, pcov = curve_fit(linear_decay_func, np.squeeze(ts), raw_sig_mat[:,ROI])
    # a, b = popt
    # fit_line_data_lin = linear_decay_func(np.squeeze(ts), a, b)



    # reg.fit(ts,raw_sig_mat[:,ROI])






    #
    # # calculate dF/F
    # PIL_gcamp = raw_sig_mat[:, int(np.size(raw_sig_mat, 1) / 2):int(np.size(raw_sig_mat, 1))]
    # ROI_gcamp = raw_sig_mat[:, (int(np.size(raw_sig_mat, 1) / np.size(raw_sig_mat, 1))-1):int(np.size(raw_sig_mat, 1) / 2)]
    #
    # # subtract PIL signal
    # mean_frame_brightness = np.mean(frame_brightness[0])
    # dF_signal = dF_win((ROI_gcamp-PIL_gcamp)+mean_frame_brightness)
    #
    # sio.savemat( sig_folder + sig_file + '.mat', mdict={'dF_data' : dF_signal})

if __name__ == '__main__':
    # test_bleaching_function()
    fit_bleaching()
