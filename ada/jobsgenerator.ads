with Ada.Unchecked_Deallocation;

package JobsGenerator is
    task type JobMaster is
    end jobMaster;

    type PJobMaster is access JobMaster;

end JobsGenerator;